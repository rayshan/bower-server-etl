module = angular.module 'B.Delta', []

module.directive "bDelta", (bDataSvc) ->
  templateUrl: 'b-delta/b-delta.html'
  restrict: 'E'
  scope:
    delta: "@" # 1-way bind
    type: "@" # num or pct

module.filter 'pct', ->
  (input) ->
    if !input?
      undefined
    else
      input *= 100
      inputAbs = Math.abs input
      inputAbs = if inputAbs < 1 then 1 else inputAbs
      # neg = if input < 0 then '- ' else '' # force a space b/t sign & num
      if input is 0 then null
      else inputAbs.toFixed(0) + '%'

module.filter 'abs', ->
  (input) ->
    Math.abs input