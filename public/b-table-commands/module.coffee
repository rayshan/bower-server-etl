module = angular.module 'B.Table.Commands', []

module.directive "bTableCommands", (bDataSvc) ->
  templateUrl: 'b-table-commands/partial.html'
  restrict: 'E'
  link: (scope) ->
    bDataSvc.fetchAllP.then (data) -> scope.commands = data.data.commands; return
    return