spawn = require("child_process").spawn

gulp = require 'gulp'
gp = do require "gulp-load-plugins"

# ==========================

gulp.task 'redis', -> spawn 'redis-server', ['./scripts/redis.conf'], {stdio: 'inherit'}
gulp.task 'server', -> spawn 'foreman', ['start'], {stdio: 'inherit'} # foreman

# ==========================

gulp.task 'default', ['redis', 'server']
