#!/bin/bash

set -o errexit
set -o pipefail

export APP_PORT=3000
export APP_DIR=/var/www/stats.bower.io
export APP_NAME=stats.bower.io
export APP_REDIS=redis-bower
export APP_PM2=scripts/processes.json

export NODE_ENV=prod

printf "WIP: $APP_NAME node app stopping...\n"
pm2 stop $APP_NAME

printf "WIP: redis for $APP_NAME node app stopping...\n"
sudo stop $APP_REDIS
