module = angular.module 'B.Table.Commands', []

module.directive "bTableCommands", (bGaSvc) ->
  templateUrl: 'b-table-commands/partial.html'
  restrict: 'E'
  link: (scope) ->
    bGaSvc.fetchCommands.then (data) ->
      scope.commands = data

    return