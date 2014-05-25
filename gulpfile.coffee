gulp = require 'gulp'
gutil = require 'gulp-util'
watch = require 'gulp-watch'
# changed = require 'gulp-changed'
# .pipe changed dest # only pass through changed files; need to know dest up-front

#less = require 'gulp-less-sourcemap'
less = require 'gulp-less'
minifyCSS = require 'gulp-minify-css'
coffee = require 'gulp-coffee'
ngAnnotate = require 'gulp-ng-annotate'
templateCache = require 'gulp-angular-templatecache'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
htmlmin = require 'gulp-htmlmin'
htmlreplace = require 'gulp-html-replace'
replace = require 'gulp-replace'

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
#  conservativeCollapse: true # otherwise <i> & text squished
  collapseBooleanAttributes: true
  removeAttributeQuotes: true
  removeRedundantAttributes: true
  caseSensitive: true
  minifyJS: true
  minifyCSS: true

# ==========================

gulp.task 'css', ->
  gulp.src './public/css/b-app.less'
    .pipe less paths: './public/b-*/b-*.less' # @import path
    .pipe minifyCSS cache: true, keepSpecialComments: 0 # remove all
    .pipe gulp.dest destPath

gulp.task 'html', ->
  gulp.src ['./public/index.html']
    .pipe htmlreplace
      js: 'b-app.js'
      css: 'b-app.css'
    .pipe replace 'dist/', ''
    .pipe htmlmin htmlminOptions
    .pipe gulp.dest destPath

gulp.task 'js', ->
  # inline templates
  ngTemplates = gulp.src './public/b-*/b-*.html'
    .pipe htmlmin htmlminOptions
    .pipe templateCache module: 'B.Templates', standalone: true # annotated already

  # compile cs & annotate for min
  ngModules = gulp.src ['./public/b-*/b-*.coffee', './public/js/b-app.coffee']
    .pipe replace 'dist/', '' # for b-map.coffee loading topojson
    .pipe replace "# 'B.Templates'", "'B.Templates'" # for b-app.coffee $templateCache
    .pipe coffee()
    .pipe ngAnnotate() # ngmin doesn't annotate coffeescript wrapped code

  # src that need min
  otherSrc = ['./public/bower_components/topojson/topojson.js']
  other = gulp.src otherSrc

  # min above
  min = streamqueue(objectMode: true, ngTemplates, ngModules, other).pipe uglify()

  # src already min
  otherMinSrc = [
    './public/bower_components/angular/angular.min.js'
    './public/bower_components/angular-bootstrap/ui-bootstrap.min.js'
    './public/bower_components/d3/d3.min.js'
  ] # order is respected
  otherMin = gulp.src otherMinSrc

  # concat
  streamqueue {objectMode: true}, otherMin, min # other 1st b/c has angular
    .pipe(concat('b-app.js')).pipe gulp.dest destPath

gulp.task 'server', -> spawn 'bash', ['./scripts/start.sh'], {stdio: 'inherit'}

# ==========================

gulp.task 'dev', ['server'], -> # not compiling js due to using un-min files
  gulp.src ['./public/b-*/b-*.less', './public/css/b-app.less']
    .pipe watch {emit: 'one', name: 'css'}, ['css']
  gulp.src ['./public/b-*/b-*.coffee', './public/js/b-app.coffee'] # './public/bower_components/**/*.js'
    .pipe watch {emit: 'one', name: 'js'}, ['js']
  gulp.src ['./public/index.html']
    .pipe watch {emit: 'one', name: 'html'}, ['html']
#  .on 'error', gutil.log

gulp.task('prod', ['css', 'js', 'html']).on 'error', gutil.log