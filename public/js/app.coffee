app = angular.module('BApp', [
	'BApp.Charts.Traffic'
	'ngResource'
])

app.controller 'BMainCtrl', () ->
	return

app.factory 'd3', -> d3

app.factory 'ga', ($http) ->
	cb = -> $rootScope.$broadcast 'gaLoaded'; return

	return