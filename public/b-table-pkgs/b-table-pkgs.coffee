module = angular.module 'B.Table.Pkgs', []

module.directive "bTablePkgs", (bDataSvc) ->
  templateUrl: 'b-table-pkgs/b-table-pkgs.html'
  restrict: 'E'
  link: (scope) ->
    reduceFunc = (period, currentOrPrior) -> (a, b, i) ->
      if (if currentOrPrior is 'current' then i >= period else i < period) then a + b else a

    bDataSvc.fetchAllP.then (data) ->
      # calc period over period totals
      data.data.packages.forEach (pkg) ->
        pkg.installsSum = []
        pkg.installsSum.push(
          (pkg.installs.reduce reduceFunc(7, 'prior'), 0)
          (pkg.installs.reduce reduceFunc(7, 'current'), 0),
        )
        return

      scope.packages = data.data.packages
      return

    scope.hideAngular = true
    scope.toggleHideAngular = ->
      scope.hideAngular = !scope.hideAngular
      return

    return