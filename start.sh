#!/bin/sh
set -e
if [ ! -f /etc/nginx/certs/shortly.crt ]; then
  mkdir -p /etc/nginx/certs
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout /etc/nginx/certs/shortly.key \
    -out    /etc/nginx/certs/shortly.crt \
    -subj "/CN=shortly.lab"
fi
node dist/server.js &
nginx -g 'daemon off;'
 