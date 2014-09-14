spawn = require("child_process").spawn

gulp = require 'gulp'
mocha = require 'gulp-mocha'

# ==========================

gulp.task 'redis', -> spawn 'redis-server', ['./scripts/redis.conf'], {stdio: 'inherit'}
gulp.task 'server', -> spawn 'foreman', ['start'], {stdio: 'inherit'} # foreman

# ==========================

gulp.task 'default', ['redis', 'server']
gulp.task 'test', ->
  gulp.src 'test/*.coffee', read: false
    .pipe mocha()
