module = angular.module('BApp.Charts.Traffic', [])

module.directive "traffic", (d3) ->
	templateUrl: 'bapp-charts-traffic/partial.html'
	restrict: 'E'
	link: (scope, ele) ->
		console.log d3
		return