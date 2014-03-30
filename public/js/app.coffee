app = angular.module 'BApp', [
  'B.Chart.Traffic'
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
      isArray: true
    }
  }

  fetchPromise = ga.getTraffic().$promise

  fetch: fetchPromise