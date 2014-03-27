module = angular.module('BApp.Charts.Traffic', [])

module.directive "traffic", (d3, ga) ->
	templateUrl: 'b-charts-traffic/partial.html'
	restrict: 'E'
	link: (scope, ele) ->
#		executeQuery = ->
#			query = gapi.client.analytics.data.ga.get {
#				'ids': '75972512'
#				'start-date': '7daysAgo'
#				'end-date': 'yesterday'
#				'metrics': 'ga:visits'
#			}
#			cb = (res) ->
#				if res.error
#					console.log "Error!" + res.message
#				else
#					console.log res
#			query.execute(cb)
#			return
#
#		scope.$on 'gaLoaded', -> console.log "loaded"; executeQuery(); return
		return