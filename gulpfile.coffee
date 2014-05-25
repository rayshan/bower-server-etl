gulp = require 'gulp'
#watch = require 'gulp-watch'
gutil = require 'gulp-util'
changed = require 'gulp-changed'

#less = require 'gulp-less-sourcemap'
less = require 'gulp-less'
minifyCSS = require 'gulp-minify-css'
coffee = require 'gulp-coffee'
ngAnnotate = require 'gulp-ng-annotate'
templateCache = require 'gulp-angular-templatecache'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
htmlmin = require 'gulp-htmlmin'

streamqueue = require 'streamqueue'

p = require 'path'

# ==========================
# TODO: only runs @ root, should run anywhere in proj dir

dest = './public/dist'

htmlminOptions =
  removeComments: true
  collapseWhitespace: true
  removeCommentsFromCDATA: true
  collapseBooleanAttributes: true
  removeAttributeQuotes: true
  removeRedundantAttributes: true
  caseSensitive: true
  minifyJS: true
  minifyCSS: true

# ==========================

gulp.task 'css', ->
  gulp.src './public/css/b-app.less'
    .pipe changed dest # only pass through changed files; need to know dest up-front
    .pipe less {
      paths: ['./public'] # @import path
    }
    .pipe minifyCSS {
      cache: true
      keepSpecialComments: 0 # remove all
    }
    .pipe gulp.dest dest

# from 3k to 1k, need to swap out index.html, not worth the effort
gulp.task 'html', ->
  gulp.src './public/index.html'
    .pipe changed dest
    .pipe htmlmin htmlminOptions
    .pipe gulp.dest dest

gulp.task 'js', ->
  # inline templates
  angularTemplates = gulp.src './public/b-*/b-*.html'
    .pipe changed dest
    .pipe htmlmin htmlminOptions
    .pipe templateCache {
      module: 'B.Templates'
      standalone: true
    } # annotated

  # compile cs & annotate for min
  angularModules = gulp.src ['./public/b-*/b-*.coffee', './public/js/b-app.coffee']
    .pipe changed dest
    .pipe coffee()
    .pipe ngAnnotate() # ngmin doesn't annotate coffeescript wrapped code

  # src that need min
  otherSrc = ['./public/bower_components/topojson/topojson.js']
  other = gulp.src(otherSrc).pipe changed dest

  # min above
  min = streamqueue {objectMode: true}, angularTemplates, angularModules, other
    .pipe uglify()

  # src already min
  otherMinSrc = [
    './public/bower_components/angular/angular.min.js'
    './public/bower_components/angular-bootstrap/ui-bootstrap.min.js'
    './public/bower_components/d3/d3.min.js'
  ] # order is respected
  otherMin = gulp.src(otherMinSrc).pipe changed dest

  # concat
  streamqueue {objectMode: true}, otherMin, min # other 1st b/c has angular
    .pipe concat 'b-app.js'
    .pipe gulp.dest dest

  # move angular.min.js.map since

gulp.task 'default', ['css', 'js']
  .on 'error', gutil.log