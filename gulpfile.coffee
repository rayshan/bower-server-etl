gulp = require 'gulp'
gp = do require "gulp-load-plugins"

spawn = require("child_process").spawn
streamqueue = require 'streamqueue'
combine = require 'stream-combiner'

p = require 'path'

# ==========================
# TODO: only runs @ root, should run anywhere in proj dir

destPath = './public/dist'

htmlminOptions =
  removeComments: true
  removeCommentsFromCDATA: true
  collapseWhitespace: true
  # conservativeCollapse: true # otherwise <i> & text squished
  collapseBooleanAttributes: true
  removeAttributeQuotes: true
  removeRedundantAttributes: true
  caseSensitive: true
  minifyJS: true
  minifyCSS: true

# ==========================

gulp.task 'css', ->
  gulp.src './public/css/b-app.less'
    # TODO: switch out font-awesome woff path w/ CDN path
    # .pipe replace "../bower_components/font-awesome/fonts", "//cdn.jsdelivr.net/fontawesome/4.1.0/fonts"
    .pipe gp.less paths: './public/b-*/b-*.less' # @import path
    .pipe gp.minifyCss cache: true, keepSpecialComments: 0 # remove all
    .pipe gulp.dest destPath

gulp.task 'html', ->
  gulp.src ['./public/index.html']
    .pipe gp.htmlReplace
      js: 'b-app.js'
      css: 'b-app.css'
    .pipe gp.replace 'dist/', ''
    .pipe gp.htmlmin htmlminOptions
    .pipe gulp.dest destPath

gulp.task 'js', ->
  # inline templates
  ngTemplates = gulp.src './public/b-*/b-*.html'
    .pipe gp.htmlmin htmlminOptions
    .pipe gp.angularTemplatecache module: 'B.Templates', standalone: true # annotated already

  # compile cs & annotate for min
  ngModules = gulp.src ['./public/b-*/b-*.coffee', './public/js/b-app.coffee']
    .pipe gp.plumber()
    .pipe gp.replace 'dist/', '' # for b-map.coffee loading topojson
    .pipe gp.replace "# 'B.Templates'", "'B.Templates'" # for b-app.coffee $templateCache
    .pipe gp.coffee()
    .pipe gp.ngAnnotate() # ngmin doesn't annotate coffeescript wrapped code

  # src that need min
  otherSrc = ['./public/bower_components/topojson/topojson.js']
  other = gulp.src otherSrc

  # min above
  min = streamqueue(objectMode: true, ngTemplates, ngModules, other)
    .pipe gp.uglify()

  # src already min
  otherMinSrc = [
    './public/bower_components/angular/angular.min.js'
    './public/bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
    './public/bower_components/d3/d3.min.js'
  ] # order is respected
  otherMin = gulp.src otherMinSrc

  # concat
  streamqueue objectMode: true, otherMin, min # other 1st b/c has angular
    .pipe gp.concat 'b-app.js'
    .pipe gulp.dest destPath

#gulp.task 'server', -> spawn 'bash', ['./scripts/start.sh'], {stdio: 'inherit'} # node-dev
gulp.task 'server', -> spawn 'foreman', ['start'], {stdio: 'inherit'} # foreman
gulp.task 'redis', -> spawn 'redis-server', ['./scripts/redis.conf'], {stdio: 'inherit'}

# ==========================

gulp.task 'dev', ->
  gulp.src ['./public/b-*/b-*.less', './public/css/b-app.less']
    .pipe gp.watch {emit: 'one', name: 'css'}, ['css']

  jsSrc = [
    './public/b-*/b-*.coffee', './public/js/b-app.coffee'
    './public/b-*/b-*.html'
    # './public/bower_components/**/*.js'
    # TODO: gulp watch can't see files added after bower install unless using glob option
  ]
  gulp.src(jsSrc).pipe gp.watch {emit: 'one', name: 'js'}, ['js']

  gulp.src ['./public/index.html']
    .pipe gp.watch {emit: 'one', name: 'html'}, ['html']

gulp.task 'prod', ['css', 'js', 'html']

gulp.task 'default', ['dev', 'redis', 'server']