#!/bin/bash

printf "host is $HOSTNAME"
if [ "$HOSTNAME" = "shan.io" ]; then
  export GA_KEY_PATH=/var/www/apps.shan.io/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
else
  export GA_KEY_PATH=~/=Projects=/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
fi

redis-server ./scripts/redis.conf

printf "\n"

redis-cli ping

printf "start script complete, starting server..."

printf "\n"

node-dev index.coffee