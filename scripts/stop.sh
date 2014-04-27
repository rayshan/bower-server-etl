#!/bin/bash

#set -o errexit
#set -o pipefail

printf "WIP: $APP_NAME node app stopping...\n"
forever stop index.coffee >> $APP_DIR/$APP_LOG

printf "WIP: redis for $APP_NAME node app stopping...\n"
redis-cli shutdown