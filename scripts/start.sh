#!/bin/bash

printf "host is $HOSTNAME\n"

export APP_PORT=3000

if [ "$HOSTNAME" = "shan.io" ]; then
  export APP_GA_KEY_PATH=/var/www/apps.shan.io/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
else
  export APP_GA_KEY_PATH=~/=Projects=/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
fi

redis-server ./scripts/redis.conf

printf "start script complete, starting server...\n"

node-dev index.coffee