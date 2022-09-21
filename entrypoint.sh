#!/bin/sh

rm -rf /run/apache2/*

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -DFOREGROUND "$@"
