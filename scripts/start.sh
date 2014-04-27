#!/bin/bash

set -o errexit
set -o pipefail

export APP_PORT=3000

if [[ "$HOSTNAME" = "shan.io" ]]; then
  printf "WIP: redis for $APP_NAME node app starting...\n"
  redis-server $APP_DIR/scripts/redis.conf
  export NODE_ENV=prod
  export APP_GA_KEY_PATH=/var/www/_keys/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
  printf "WIP: $APP_NAME node app starting...\n"
  forever start --append -l $APP_DIR/$APP_LOG --minUptime 1000 --spinSleepTime 10000 -c coffee index.coffee >> $APP_DIR/$APP_LOG
  forever list >> $APP_DIR/$APP_LOG
else
  source ./scripts/dev.sh
  export NODE_ENV=dev
  export APP_GA_KEY_PATH=~/=Projects=/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem
  redis-server ./scripts/redis.conf
  node-dev index.coffee
fi

