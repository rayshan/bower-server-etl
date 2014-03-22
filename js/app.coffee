app = angular.module('BApp', [
	"BApp.Charts.Traffic"
])

app.controller 'BMainCtrl', () ->
	return

app.factory 'd3', -> d3