#!/bin/bash

redis-server ./scripts/redis.conf

export APP_PORT=3000

printf "host is $HOSTNAME\n"
if [[ "$HOSTNAME" = "shan.io" ]]; then
  export NODE_ENV=prod
  export APP_GA_KEY_PATH=/var/www/apps.shan.io/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
  forever -c coffee index.coffee
else
  export NODE_ENV=dev
  export APP_GA_KEY_PATH=~/=Projects=/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
  node-dev index.coffee
fi