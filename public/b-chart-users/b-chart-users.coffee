module = angular.module 'B.Chart.Users', []

module.service 'bChartUserData', ($q, bDataSvc, d3) ->
  parseData = (data) ->
    _deferred = $q.defer()

    data = data.data.users
    parseDate = d3.time.format("%Y%m%d").parse # e.g. 20140301
    data.forEach (d) -> d[1] = parseDate d[1]; return # date
    data = d3.nest().key((d) -> d[0]).entries data # group by key; apply to data

    totalUsersByDay = data[0].values.map (ele, i, arr) ->
      day: arr[i][1]
      users: ele[2] + data[1].values[i][2]
    maxUsers = d3.max totalUsersByDay, (d) -> d.users
    maxUsersDayI = null
    totalUsersByDay.filter (ele, i) -> ele.users is maxUsers && maxUsersDayI = i
#    minUsers = d3.min totalUsersByDay, (d) -> d.users
#    minUsersDayI = null
#    totalUsersByDay.filter (ele, i) -> ele.users is minUsers && minUsersDayI = i

    _deferred.resolve
      data: data
      maxUsers: maxUsers
      maxUsersDayI: maxUsersDayI
#      minUsers: minUsers
#      minUsersDayI: minUsersDayI
    _deferred.promise

  bDataSvc.fetchAllP.then parseData

module.directive "bChartUsers", (d3, bChartUserData) ->
  templateUrl: 'b-chart-users/b-chart-users.html'
  restrict: 'E'
  link: (scope, ele) ->
    render = (data) ->
      canvas = ele[0].querySelector(".b-chart.b-users").children[0]
      # d3.select(canvas).node().offsetWidth doesn't work in FF
      wOrig = ele.children()[1].clientWidth
      hOrig = ele.children()[1].clientHeight
      marginBase = 30
      margin =
        t: marginBase * 1.5 # accommodate for maxUsers label
        l: marginBase * 1.5 # accommodate for y axis
        r: marginBase
        b: marginBase
      w = wOrig - margin.l - margin.r
      h = hOrig - margin.t - margin.b

      x = d3.time.scale()
        .range [0, w]
        .domain d3.extent data.data[1].values, (d) -> d[1]
      y = d3.scale.linear()
        .range [h, 0]
        .domain [0, data.maxUsers]

      xAxis = d3.svg.axis()
        .scale x
        .ticks d3.time.weeks
        .orient "bottom"
      yAxis = d3.svg.axis() # & grid
        .scale y
        .orient "left"
        .ticks 6
        .tickSize -w, 0

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

      svg = d3.select(canvas)
          .attr "width", w + margin.l + margin.r
          .attr "height", h + margin.t + margin.b
        .append "g" # need to wrap in g to transform
          .attr "transform", "translate(#{ margin.l }, #{ margin.t })"

      users = svg.selectAll ".users"
          .data stack data.data # , (d) -> d.key
        .enter().append "g"
          .attr "class", (d) -> "users " + d.key

      users.append "path"
        .attr "class", "area"
        .attr "d", (d) -> area(d.values)
        .attr "data-legend", (d) -> d.key

      users.selectAll "text"
          .data (d) -> d.values.filter (ele, i) -> i is data.maxUsersDayI # or i is data.minUsersDayI
        .enter().append "text"
          .attr "x", (d) -> x d[1]
          .attr "y", (d) -> y d.y + d.y0
          .attr "transform", "translate(0, -15)"
          .text (d) -> d3.format('0,000') d[2]

      users.selectAll "circle"
          .data (d) -> d.values.filter (ele, i) -> i is data.maxUsersDayI # or i is data.minUsersDayI
        .enter().append "circle"
          .attr "cx", (d) -> x d[1]
          .attr "cy", (d) -> y d.y + d.y0
          .attr "r", "0.4em"

      svg.append "g"
        .attr "class", "axis x"
        .attr "transform", "translate(0, #{ h })"
        .call xAxis
      svg.append "g"
        .attr "class", "axis y"
        .call yAxis

      legend = svg.append "g"
        .attr "class", "legend"
        .attr "transform", "translate(0, #{-marginBase / 2})"
        .call d3.legend

      return

    bChartUserData.then render
    return

