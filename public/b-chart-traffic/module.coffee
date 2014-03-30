module = angular.module 'B.Chart.Traffic', []

module.directive "bChartTraffic", (d3, bGaSvc) ->
  templateUrl: 'b-chart-traffic/partial.html'
  restrict: 'E'
  link: (scope, ele, attrs) ->
    render = (data) ->
      parseDate = d3.time.format("%Y%m%d").parse # e.g. 20140301
      data.forEach (d) ->
        d[1] = parseDate(d[1]) # date
        d[2] = +d[2] # users
        return

      data = d3.nest()
        .key (d) -> d[0] # group by this key
        .entries data # apply to this data

      console.log data

      canvas = ele[0].querySelector(".b-chart-traffic").children[0]
      wOrig = d3.select(canvas).node().offsetWidth
      hOrig = d3.select(canvas).node().offsetHeight
      marginBase = 30
      margin =
        t: marginBase
        l: marginBase, r: marginBase
        b: marginBase
      w = wOrig - margin.l - margin.r
      h = hOrig - margin.t - margin.b

      x = d3.time.scale()
        .range [0, w]
        .domain d3.extent data[1].values, (d) -> d[1]
      maxUsers = d3.max data, (d) -> d3.max d.values, (d) -> d[2]
      y = d3.scale.linear()
        .range [h, 0]
        .domain [0, maxUsers]

      xAxis = d3.svg.axis().scale(x).orient "bottom"

      area = d3.svg.area()
        .x (d) -> x d[1]
        .y0 h
        .y1 (d) -> y d[2]
        .interpolate "cardinal"

      svg = d3.select canvas
        .append "svg"
        .attr "width", w + margin.l + margin.r
        .attr "height", h + margin.t + margin.b
        .append "g"
        .attr "transform", "translate(#{ margin.l }, #{ margin.t })"

      areas = svg.selectAll ".traffic"
          .data data, (d) -> d.key
        .enter().append "g"
          .attr "class", "traffic"

      areas.append "path"
        .attr "class", (d) -> "area " + d.key
        .attr "d", (d) -> area(d.values)

      svg.append "g"
        .attr "class", "axis x"
        .attr "transform", "translate(0, #{ h })"
        .call xAxis

      return

    bGaSvc.fetch.then render
    return

