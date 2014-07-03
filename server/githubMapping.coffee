# manual mapping b/t bower pkg name and github owner/repo name pairs
# due to package owners using bower-specific repos, e.g. https://github.com/angular/bower-angular

module.exports =
  'angular': 'angular/angular.js' # bower-specific repo
  'angular-translate': 'angular-translate/angular-translate' # moved from git://github.com/PascalPrecht/bower-angular-translate.git
  'bootstrap-sass': 'twbs/bootstrap-sass' # moved from git://github.com/jlong/sass-twitter-bootstrap
  'sass-bootstrap': 'twbs/bootstrap-sass' # moved from git://github.com/jlong/sass-bootstrap.git
  'angular-bootstrap': 'angular-ui/bootstrap'
  'requirejs': 'jrburke/requirejs'
  'jquery-ui': 'jquery/jquery-ui'
  'handlebars': 'wycats/handlebars.js'
  'ember': 'emberjs/ember.js'
  'foundation': 'zurb/foundation'
  'ember-data': 'emberjs/data'
  'less': 'less/less.js'
  'angular-translate-loader-static-files': 'angular-translate/bower-angular-translate-loader-static-files'
  'highlightjs': 'isagalaev/highlight.js'
  'polymer': 'Polymer/polymer'