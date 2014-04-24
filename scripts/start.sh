#!/bin/bash

set -o errexit
set -o pipefail

printf "WIP: redis for $APP_NAME node app starting...\n"
redis-server ./scripts/redis.conf

printf "WIP: $APP_NAME node app starting...\n"
export APP_PORT=3000
printf "host is $HOSTNAME\n"
if [[ "$HOSTNAME" = "shan.io" ]]; then
  export NODE_ENV=prod
  export APP_GA_KEY_PATH=/var/www/_keys/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
  exec forever start \
    --append -l $APP_DIR/$APP_LOG \
    --minUptime 1000 --spinSleepTime 10000 \
    -c coffee index.coffee >> $APP_DIR/$APP_LOG
else
  source ./scripts/dev.sh
  export NODE_ENV=dev
  export APP_GA_KEY_PATH=~/=Projects=/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
  node-dev index.coffee
fi
