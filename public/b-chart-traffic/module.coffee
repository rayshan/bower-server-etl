module = angular.module 'B.Chart.Traffic', []

module.directive "bChartTraffic", (d3, bGaSvc) ->
  templateUrl: 'b-chart-traffic/partial.html'
  restrict: 'E'
  link: (scope, ele, attrs) ->
    render = (data) -> console.log data; return
    gaSvc.fetch.then render
    return
