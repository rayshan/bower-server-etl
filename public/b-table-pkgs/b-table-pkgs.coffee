module = angular.module 'B.Table.Pkgs', []

module.directive "bTablePkgs", (bGaSvc) ->
  templateUrl: 'b-table-pkgs/b-table-pkgs.html'
  restrict: 'E'
  link: (scope, ele) ->
    bGaSvc.fetchPkgs.then (data) ->
      scope.pkgs = data

    scope.hideAngular = true
    scope.toggleHideAngular = ->
      scope.hideAngular = !scope.hideAngular
      return

    return