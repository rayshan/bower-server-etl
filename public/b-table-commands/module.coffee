module = angular.module 'B.Table.Commands', []

module.directive "bTableCommands", (bDataSvc) ->
  templateUrl: 'b-table-commands/partial.html'
  restrict: 'E'
  link: (scope) ->
    bDataSvc.fetchCommands.then (data) ->
      scope.commands = data

    return