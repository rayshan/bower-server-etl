app = angular.module 'BApp', [
  'B.Chart.Users'
  'B.Table.Cmds'
  'B.Table.Pkgs'
  'B.Map'
  'B.Delta'
  'ui.bootstrap' # TODO: use custom build
  # 'B.Templates'
]

app.factory 'bDataSvc', ($http) -> fetchAllP: $http.get "/api/1/data/all"

# period over period helper funcs
app.factory 'bPoP', ->
  _reduceFunc = (period, currentOrPrior) -> (a, b, i) ->
    if (if currentOrPrior is 'current' then i >= period else i < period) then a + b else a

  process: (data, period) ->
    [
      data.reduce _reduceFunc(period, 'prior'), 0
      data.reduce _reduceFunc(period, 'current'), 0
    ]

app.factory 'd3', -> d3

app.controller 'BHeaderCtrl', (bDataSvc) ->
  bDataSvc.fetchAllP.then (data) => @pkgs = data.data.overview.totalPackages; return
  return

app.filter 'round', ->
  (input, decimals) ->
    if !input?
      undefined
    else if input >= 1000
      (input / 1000).toFixed(1) + ' k' # e.g. 206.1 k; toFixed() returns string
    else input.toFixed decimals
