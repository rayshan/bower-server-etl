module = angular.module 'B.Table.Cmds', []

module.directive "bTableCmds", (bDataSvc) ->
  templateUrl: 'b-table-cmds/b-table-cmds.html'
  restrict: 'E'
  link: (scope) ->
    bDataSvc.fetchAllP.then (data) -> scope.cmds = data.data.cmds; return
    return