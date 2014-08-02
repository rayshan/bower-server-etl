(function() {
  var module;

  module = angular.module('B.Chart.Users', []);

  module.service('bChartUserData', ["$q", "bDataSvc", "d3", function($q, bDataSvc, d3) {
    var movingAverage, parseArray, parseData;
    parseArray = function(dataArr) {
      var mAvg, parseDate;
      mAvg = movingAverage(dataArr, 7, function(d) {
        return d[2];
      });
      parseDate = d3.time.format("%Y%m%d").parse;
      return dataArr.slice(6).map(function(d, i) {
        return {
          key: d[0],
          date: parseDate(d[1]),
          val: d[2],
          movingAvg: mAvg[i]
        };
      });
    };
    parseData = function(data) {
      var existingUsersData, newUsersData, npmInstallsData, _deferred;
      _deferred = $q.defer();
      data = data.data.users;
      data = d3.nest().key(function(d) {
        return d[0];
      }).entries(data);
      newUsersData = parseArray(data[0].values);
      existingUsersData = parseArray(data[1].values);
      npmInstallsData = parseArray(data[2].values);
      data = [newUsersData, existingUsersData, npmInstallsData];
      _deferred.resolve({
        data: data
      });
      return _deferred.promise;
    };
    movingAverage = function(dataArr, numDaysToAverage, accessor) {
      var avg, d, out, stack, x, _i, _len;
      stack = [];
      out = [];
      for (_i = 0, _len = dataArr.length; _i < _len; _i++) {
        d = dataArr[_i];
        x = accessor != null ? accessor(d) : d;
        stack.unshift(x);
        if (stack.length === numDaysToAverage) {
          avg = d3.sum(stack) / numDaysToAverage;
          out.push(avg);
          stack.pop();
        }
      }
      return out;
    };
    return bDataSvc.fetchAllP.then(parseData);
  }]);

  module.directive("bChartUsers", ["d3", "bChartUserData", function(d3, bChartUserData) {
    return {
      templateUrl: 'b-chart-users/b-chart-users.html',
      restrict: 'E',
      compile: function() {
        var render;
        render = function(data) {
          var addY, area_existing, area_new, center, chart, colorScale, domainer, existingUsersData, format, gridlines, installsLabel, legend, line_installs, newUsersData, npmData, stack, stackedData, usersLabel, xAxis, xScale, yAxisInstalls, yAxisUsers, yScaleInstalls, yScaleUsers;
          stack = d3.layout.stack().values(function(d) {
            return d;
          }).x(function(d) {
            return d.date;
          }).y(function(d) {
            return d.movingAvg;
          }).order("reverse");
          stackedData = stack(data.data.slice(0, 2));
          newUsersData = stackedData[0];
          existingUsersData = stackedData[1];
          npmData = data.data[2];
          xScale = new Plottable.Scale.Time();
          yScaleUsers = new Plottable.Scale.Linear();
          yScaleInstalls = new Plottable.Scale.Linear();
          xScale.domainer(new Plottable.Domainer().pad(0));
          domainer = new Plottable.Domainer().addIncludedValue(0).pad(0.2).addPaddingException(0);
          yScaleUsers.domainer(domainer).ticks(5);
          yScaleInstalls.domainer(domainer).ticks(5);
          colorScale = (new Plottable.Scale.Color()).domain(["New Users", "Existing Users", "npm Installs"]).range(["#00acee", "#ffcc2f", "#EF5734"]);
          xAxis = new Plottable.Axis.Time(xScale, "bottom");
          format = function(n) {
            return Math.round(n / 1000).toString() + "k";
          };
          yAxisUsers = new Plottable.Axis.Numeric(yScaleUsers, "left", format);
          yAxisInstalls = new Plottable.Axis.Numeric(yScaleInstalls, "right", format);
          gridlines = new Plottable.Component.Gridlines(xScale, yScaleUsers);
          legend = new Plottable.Component.Legend(colorScale).xAlign("left");
          usersLabel = new Plottable.Component.AxisLabel("Daily Active Users", "left");
          installsLabel = new Plottable.Component.AxisLabel("Daily npm Installs", "left");
          addY = function(d) {
            return d.y0 + d.y;
          };
          area_existing = (new Plottable.Plot.Area(existingUsersData, xScale, yScaleUsers)).project("x", "date", xScale).project("y0", "y0", yScaleUsers).project("y", addY, yScaleUsers).classed("existing-users", true);
          area_new = (new Plottable.Plot.Area(newUsersData, xScale, yScaleUsers)).project("x", "date", xScale).project("y0", "y0", yScaleUsers).project("y", addY, yScaleUsers).classed("new-users", true);
          line_installs = (new Plottable.Plot.Line(npmData, xScale, yScaleInstalls)).project("x", "date", xScale).project("y", "movingAvg", yScaleInstalls).classed("npm-installs", true);
          center = area_existing.merge(area_new).merge(line_installs).merge(gridlines).merge(legend);
          chart = new Plottable.Component.Table([[usersLabel, yAxisUsers, center, yAxisInstalls, installsLabel], [null, null, xAxis, null, null]]).renderTo("#users-chart");
        };
        bChartUserData.then(render);
      }
    };
  }]);

}).call(this);
