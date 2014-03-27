app = angular.module 'BApp', [
  'B.Charts.Traffic'
  'ngResource'
]

app.controller 'BMainCtrl', () ->
  return

app.factory 'd3', -> d3

app.factory 'bGaSvc', ($resource, $rootScope) ->
  ga = $resource '/data/:type', null, {
    getTraffic: {
      method: 'GET'
      params: {type: 'traffic'}
    }
  }

  fetchPromise = ga.getTraffic().$promise
  console.log "fetched"

  fetch: fetchPromise