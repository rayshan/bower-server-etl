module = angular.module 'B.Delta', []

module.directive "bDelta", (bGaSvc) ->
  templateUrl: 'b-delta/b-delta.html'
  restrict: 'E'
  scope:
    delta: "@" # 1-way bind
    type: "@" # num or pct
  controller: ($scope) ->
    return
  link: (scope, ele, attr) ->
    return

module.filter 'pct', ->
  (input) ->
    if !input?
      undefined
    else
      input *= 100
      inputAbs = Math.abs input
      # neg = if input < 0 then '- ' else '' # force a space b/t sign & num
      decimal = if inputAbs < 10 then 1 else 0
      if input is 0 then null
      else inputAbs.toFixed(decimal) + '%'