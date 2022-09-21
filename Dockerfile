# Final Stage: Build the Real Image
FROM ubuntu:20.04

# Copy CAs from previous stage
#COPY --from=ca-certificates /etc/ssl/certs/ /etc/ssl/certs/
#COPY --from=ca-certificates /usr/local/share/ca-certificates/ /usr/local/share/ca-certificates/
# We don't have to run 'apt update' twice
#COPY --from=ca-certificates /var/lib/apt/lists/ /var/lib/apt/lists/

RUN apt-get update && apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      libapache2-mod-php7.4 \
      # Used by drush to create/drop DBs on fresh install
      mysql-client \
      php7.4 \
      php7.4-cli \
      php7.4-gd \
      php7.4-json \
      php7.4-mbstring \
      php7.4-mysql \
      php7.4-opcache \
      php7.4-xml \
      php7.4-xmlrpc \
      php-igbinary \
      php-memcached \
      php-zip \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite && a2enmod remoteip

# Make sure apache has permissions to write
RUN chown -R www-data:www-data /var/log/apache2 /run/apache2

# Apache can't listen on 80 when not starting as root
RUN sed -i 's/^Listen 80$/#Listen 80/' /etc/apache2/ports.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

ENV APACHE_MAX_REQUEST_WORKERS 150
ENV OPCACHE_MEMORY_CONSUMPTION 128
ENV PHP_MEMORY_LIMIT 250M

RUN { \
    echo '<IfModule mpm_prefork_module>'; \
    echo '  StartServers 5'; \
    echo '  MinSpareServers 5'; \
    echo '  MaxSpareServers 10'; \
    echo '  MaxRequestWorkers ${APACHE_MAX_REQUEST_WORKERS}'; \
    echo '  MaxConnectionsPerChild 0'; \
    echo '</IfModule>'; \
  } > /etc/apache2/mods-enabled/mpm_prefork.conf

# Set recommended opcache settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
	} > /etc/php/7.4/apache2/conf.d/opcache-recommended.ini

RUN { \
    echo 'expose_php=Off'; \
    echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
    echo 'post_max_size=10M'; \
    echo 'upload_max_filesize = 10M'; \
	} > /etc/php/7.4/apache2/conf.d/php-defaults.ini

RUN { \
		echo 'RemoteIPHeader X-Real-IP'; \
	} > /etc/apache2/mods-enabled/remoteip.conf

USER www-data

ENTRYPOINT /usr/local/bin/entrypoint.sh
