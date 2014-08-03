gulp = require 'gulp'
gp = do require "gulp-load-plugins"

spawn = require("child_process").spawn
streamqueue = require 'streamqueue'
combine = require 'stream-combiner'

#p = require 'path'

# ==========================

#gulp.task 'server', -> spawn 'bash', ['./scripts/start.sh'], {stdio: 'inherit'} # node-dev
gulp.task 'server', -> spawn 'foreman', ['start'], {stdio: 'inherit'} # foreman
gulp.task 'redis', -> spawn 'redis-server', ['./scripts/redis.conf'], {stdio: 'inherit'}

# ==========================

gulp.task 'default', ['redis', 'server']
