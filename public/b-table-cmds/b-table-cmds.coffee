module = angular.module 'B.Table.Commands', []

module.directive "bTableCommands", (bDataSvc) ->
  templateUrl: 'b-table-cmds/b-table-cmds.html'
  restrict: 'E'
  link: (scope) ->
    bDataSvc.fetchAllP.then (data) -> scope.commands = data.data.commands; return
    return