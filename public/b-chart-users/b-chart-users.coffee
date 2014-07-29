module = angular.module 'B.Chart.Users', []

module.service 'bChartUserData', ($q, bDataSvc, d3) ->
  parseData = (data) ->
    _deferred = $q.defer()

    data = data.data.users
    parseDate = d3.time.format("%Y%m%d").parse # e.g. 20140301
    data.forEach (d) -> d[1] = parseDate d[1]; return # date
    data = d3.nest().key((d) -> d[0]).entries data # group by key; apply to data

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
        .values (d) -> d.values
        .x (d) -> d[1]
        .y (d) -> d[2]
        .order "reverse"

      usersData = data.data.slice(0, 2)
      npmData = data.data[2]
      stackedData = stack usersData
      newUsersData = stackedData[0].values
      existingUsersData = stackedData[1].values

      xScale = new Plottable.Scale.Time()
      yScale = new Plottable.Scale.Linear()
      colorScale = new Plottable.Scale.Color().domain(["New Users", "Existing Users"]).range(["#00acee", "#ffcc2f"])

      xAxis = new Plottable.Axis.Time(xScale, "bottom")
      yAxis = new Plottable.Axis.Numeric(yScale, "left")

      addY = (d) -> d.y0 + d.y
      area_existing = new Plottable.Plot.Area(existingUsersData, xScale, yScale)
        .project("x", "1", xScale)
        .project("y0", "y0", yScale)
        .project("y", addY, yScale)
        .project("fill-opacity", 1)
        .project("fill", () -> "#ffcc2f")

      area_new = new Plottable.Plot.Area(newUsersData, xScale, yScale)
        .project("x", "1", xScale)
        .project("y0", "y0", yScale)
        .project("y", addY, yScale)
        .project("fill", () -> "#00acee")
        .project("fill-opacity", 1)

      gridlines = new Plottable.Component.Gridlines(xScale, yScale)
      legend = new Plottable.Component.Legend(colorScale)
      center = gridlines.merge(area_existing).merge(area_new).merge(legend)
      chart = new Plottable.Template.StandardChart().center(center).xAxis(xAxis).yAxis(yAxis)
      chart.renderTo("#users-chart")

      return

    bChartUserData.then render
    return

