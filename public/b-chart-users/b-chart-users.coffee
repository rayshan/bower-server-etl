module = angular.module 'B.Chart.Users', []


module.service 'bChartUserData', ($q, bDataSvc, d3) ->
  parseArray = (dataArr) ->
    # in: [key, dateStr, val]
    # out: {key: str, date: date, val: num, movingAvg: num}
    mAvg = movingAverage(dataArr, 7, (d) -> d[2])
    parseDate = d3.time.format("%Y%m%d").parse # e.g. 20140301
    dataArr.slice(6).map (d, i) ->
      key: d[0],
      date: parseDate(d[1]),
      val: d[2],
      movingAvg: mAvg[i]

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

      stackedData = stack data.data.slice(0, 2)
      newUsersData = stackedData[0]
      existingUsersData = stackedData[1]
      npmData = data.data[2]

      xScale = new Plottable.Scale.Time()
      yScaleUsers    = new Plottable.Scale.Linear()
      yScaleInstalls = new Plottable.Scale.Linear()

      # disable auto-padding on the date axis since it looks ugly when compared with areaPlots
      xScale.domainer(new Plottable.Domainer().pad(0))
      # Make sure the yScales both include 0 and add padding on top. Also, they look better w/ fewer ticks
      domainer = new Plottable.Domainer().addIncludedValue(0).pad(0.2).addPaddingException(0)
      yScaleUsers   .domainer(domainer).ticks(5)
      yScaleInstalls.domainer(domainer).ticks(5)

      colorScale = new Plottable.Scale.Color() # Only used to generate legend right now
                        .domain(["New Users", "Existing Users", "NPM Installs"])
                        .range(["#00acee", "#ffcc2f", "#EF5734"])

      xAxis         = new Plottable.Axis.Time(xScale, "bottom")
      format = (n) -> Math.round(n/1000).toString() + "k"
      yAxisUsers    = new Plottable.Axis.Numeric(yScaleUsers, "left", format)
      yAxisInstalls = new Plottable.Axis.Numeric(yScaleInstalls, "right", format)

      gridlines     = new Plottable.Component.Gridlines(xScale, yScaleUsers)
      legend        = new Plottable.Component.Legend(colorScale).xAlign("left")
      usersLabel    = new Plottable.Component.AxisLabel("Daily Active Users", "left")
      installsLabel = new Plottable.Component.AxisLabel("Daily npm Installs", "left")

      addY = (d) -> d.y0 + d.y
      area_existing = new Plottable.Plot.Area(existingUsersData, xScale, yScaleUsers)
        .project("x", "date", xScale)
        .project("y0", "y0", yScaleUsers)
        .project("y", addY, yScaleUsers)
        .classed("existing-users", true)

      area_new = new Plottable.Plot.Area(newUsersData, xScale, yScaleUsers)
        .project("x", "date", xScale)
        .project("y0", "y0", yScaleUsers)
        .project("y", addY, yScaleUsers)
        .classed("new-users", true);

      line_installs = new Plottable.Plot.Line(npmData, xScale, yScaleInstalls)
        .project("x", "date", xScale)
        .project("y", "movingAvg", yScaleInstalls)
        .classed("npm-installs", true);

      center = area_existing.merge(area_new).merge(line_installs).merge(gridlines).merge(legend)
      chart = new Plottable.Component.Table([
          [usersLabel, yAxisUsers, center     , yAxisInstalls, installsLabel],
          [null      , null      , xAxis      , null         , null         ]
        ]).renderTo("#users-chart");

      return

    bChartUserData.then render
    return

