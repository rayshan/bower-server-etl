module = angular.module 'B.Table.Cmds', []

module.directive "bTableCmds", (bDataSvc, bPoP) ->
  templateUrl: 'b-table-cmds/b-table-cmds.html'
  restrict: 'E'
  link: (scope) ->
    bDataSvc.fetchAllP.then (data) ->
      data.data.commands.forEach (cmdObj) ->
        cmdObj.usersSum = bPoP.process cmdObj.users, 7
        cmdObj.usesSum = bPoP.process cmdObj.uses, 7
        cmdObj.packagesSum = bPoP.process cmdObj.packages, 7 if cmdObj.packages
        return

      scope.cmds = data.data.commands
      return

    return