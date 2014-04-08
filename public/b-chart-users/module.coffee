module = angular.module 'B.Chart.Users', []

module.directive "bChartUsers", (d3, bGaSvc) ->
  templateUrl: 'b-chart-users/partial.html'
  restrict: 'E'
  link: (scope, ele) ->
    render = (data) ->
      parseDate = d3.time.format("%Y%m%d").parse # e.g. 20140301
      data.forEach (d) ->
        d[1] = parseDate(d[1]) # date
        return

      data = d3.nest()
        .key (d) -> d[0] # group by this key
        .entries data # apply to this data

      totalUsersByDay = data[0].values.map (ele, i, arr) ->
        res =
          day: arr[i][1]
          users: ele[2] + data[1].values[i][2]

      maxUsers = d3.max totalUsersByDay, (d) -> d.users
      maxUsersDayI = null
      totalUsersByDay.filter (ele, i) -> ele.users is maxUsers && maxUsersDayI = i
      minUsers = d3.min totalUsersByDay, (d) -> d.users
      minUsersDayI = null
      totalUsersByDay.filter (ele, i) -> ele.users is minUsers && minUsersDayI = i

      canvas = ele[0].querySelector(".b-chart.b-users").children[0]
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
      y = d3.scale.linear()
        .range [h, 0]
        .domain [0, maxUsers]

      xAxis = d3.svg.axis().scale(x).orient "bottom"

      area = d3.svg.area()
        .x (d) -> x d[1]
        .y0 (d) -> y d.y0
        .y1 (d) -> y d.y0 + d.y
        .interpolate "cardinal"

      stack = d3.layout.stack()
        .values (d) -> d.values
        .x (d) -> d[1]
        .y (d) -> d[2]
        .order "reverse"

      svg = d3.select(canvas).append "svg"
          .attr "width", w + margin.l + margin.r
          .attr "height", h + margin.t + margin.b
        .append "g"
          .attr "transform", "translate(#{ margin.l }, #{ margin.t })"

      users = svg.selectAll ".users"
          .data stack data # , (d) -> d.key
        .enter().append "g"
          .attr "class", (d) -> "users " + d.key

      users.append "path"
        .attr "class", "area"
        .attr "d", (d) -> area(d.values)
        .attr "data-legend", (d) -> d.key

      users.selectAll "text"
          .data (d) -> d.values.filter (ele, i) -> i is maxUsersDayI or i is minUsersDayI
        .enter().append "text"
          .attr "x", (d) -> x d[1]
          .attr "y", (d) -> y d.y + d.y0
          .attr "transform", "translate(0, -15)"
          .text (d) -> d3.format('0,000') d[2]

      users.selectAll "circle"
          .data (d) -> d.values.filter (ele, i) -> i is maxUsersDayI or i is minUsersDayI
        .enter().append "circle"
          .attr "cx", (d) -> x d[1]
          .attr "cy", (d) -> y d.y + d.y0
          .attr "r", "0.4em"

      svg.append "g"
        .attr "class", "axis x"
        .attr "transform", "translate(0, #{ h })"
        .call xAxis

      legend = svg.append "g"
        .attr "class", "legend"
#        .attr "transform", "translate(50,30)"
        .call d3.legend

      return

    bGaSvc.fetch.then render
    return

