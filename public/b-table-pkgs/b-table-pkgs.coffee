module = angular.module 'B.Table.Pkgs', []

module.directive "bTablePkgs", (bDataSvc) ->
  templateUrl: 'b-table-pkgs/b-table-pkgs.html'
  restrict: 'E'
  link: (scope) ->
    bDataSvc.fetchAllP.then (data) -> scope.pkgs = data.data.pkgs; return

    scope.hideAngular = true
    scope.toggleHideAngular = ->
      scope.hideAngular = !scope.hideAngular
      return

    return