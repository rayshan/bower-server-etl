module = angular.module 'B.Chart.Users', []

movingAverage = (dataArr, numDaysToAverage, accessor) ->
  stack = []
  out = []
  for d in dataArr
    x = if accessor? then accessor(d) else d
    stack.unshift(x)
    if stack.length == numDaysToAverage
      avg = d3.sum(stack) / numDaysToAverage
      out.push(avg)
      stack.pop()
  out

module.service 'bChartUserData', ($q, bDataSvc, d3) ->
  parseArray = (dataArr) ->
    # in: [key, dateStr, val]
    # out: {key: str, date: date, val: num, movingAvg: num}
    mAvg = movingAverage(dataArr, 7, (d) -> d[2])
    parseDate = d3.time.format("%Y%m%d").parse # e.g. 20140301
    dataArr.slice(6).map((d, i) -> {
      key: d[0],
      date: parseDate(d[1]),
      val: d[2],
      movingAvg: mAvg[i]}
    )

  parseData = (data) ->
    _deferred = $q.defer()

    data = data.data.users
    data = d3.nest().key((d) -> d[0]).entries data # group by key; apply to data
    newUsersData      = parseArray data[0].values
    existingUsersData = parseArray data[1].values
    npmInstallsData   = parseArray data[2].values
    data = [newUsersData, existingUsersData, npmInstallsData]
    _deferred.resolve
      data: data
    _deferred.promise

  bDataSvc.fetchAllP.then parseData

module.directive "bChartUsers", (d3, bChartUserData) ->
  templateUrl: 'b-chart-users/b-chart-users.html'
  restrict: 'E'
  link: (scope, ele) ->
    render = (data) ->
      stack = d3.layout.stack()
        .values (d) -> d
        .x (d) -> d.date
        .y (d) -> d.movingAvg
        .order "reverse"

      usersData = data.data.slice(0, 2)
      npmData = data.data[2]
      stackedData = stack usersData
      newUsersData = stackedData[0]
      existingUsersData = stackedData[1]

      xScale = new Plottable.Scale.Time()
      xScale.domainer(new Plottable.Domainer().pad(0)) # Disable auto-padding on the scale
      yScale = new Plottable.Scale.Linear()
      colorScale = new Plottable.Scale.Color().domain(["New Users", "Existing Users"]).range(["#00acee", "#ffcc2f"])
      xAxis = new Plottable.Axis.Time(xScale, "bottom")
      yAxis = new Plottable.Axis.Numeric(yScale, "left")

      addY = (d) -> d.y0 + d.y
      area_existing = new Plottable.Plot.Area(existingUsersData, xScale, yScale)
        .project("x", "date", xScale)
        .project("y0", "y0", yScale)
        .project("y", addY, yScale)
        .classed("existing-users", true)

      area_new = new Plottable.Plot.Area(newUsersData, xScale, yScale)
        .project("x", "date", xScale)
        .project("y0", "y0", yScale)
        .project("y", addY, yScale)
        .classed("new-users", true);

      gridlines = new Plottable.Component.Gridlines(xScale, yScale)
      legend = new Plottable.Component.Legend(colorScale)
      center = area_existing.merge(area_new).merge(gridlines)
      chart = new Plottable.Component.Table([
          [null, legend],
          [yAxis, center],
          [null,  xAxis]
        ]);
      chart.renderTo("#users-chart")

      return

    bChartUserData.then render
    return

