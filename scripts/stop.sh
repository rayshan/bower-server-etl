#!/bin/bash

set -o errexit
set -o pipefail

#printf "WIP: redis for $APP_NAME node app stopping...\n"
#redis-cli shutdown

printf "WIP: $APP_NAME node app stopping...\n"
if [[ "$HOSTNAME" = "shan.io" ]]; then
  forever list >> $APP_DIR/$APP_LOG
  forever stop index.coffee >> $APP_DIR/$APP_LOG
  forever list >> $APP_DIR/$APP_LOG
fi
