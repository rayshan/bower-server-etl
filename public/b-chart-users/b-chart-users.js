(function() {
  var module, movingAverage;

  module = angular.module('B.Chart.Users', []);

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

  module.service('bChartUserData', ["$q", "bDataSvc", "d3", function($q, bDataSvc, d3) {
    var parseArray, parseData;
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
    return bDataSvc.fetchAllP.then(parseData);
  }]);

  module.directive("bChartUsers", ["d3", "bChartUserData", function(d3, bChartUserData) {
    return {
      templateUrl: 'b-chart-users/b-chart-users.html',
      restrict: 'E',
      link: function(scope, ele) {
        var render;
        render = function(data) {
          var addY, area_existing, area_new, center, chart, colorScale, existingUsersData, gridlines, legend, newUsersData, npmData, stack, stackedData, usersData, xAxis, xScale, yAxis, yScale;
          stack = d3.layout.stack().values(function(d) {
            return d;
          }).x(function(d) {
            return d.date;
          }).y(function(d) {
            return d.movingAvg;
          }).order("reverse");
          usersData = data.data.slice(0, 2);
          npmData = data.data[2];
          stackedData = stack(usersData);
          newUsersData = stackedData[0];
          existingUsersData = stackedData[1];
          xScale = new Plottable.Scale.Time();
          xScale.domainer(new Plottable.Domainer().pad(0));
          yScale = new Plottable.Scale.Linear();
          colorScale = new Plottable.Scale.Color().domain(["New Users", "Existing Users"]).range(["#00acee", "#ffcc2f"]);
          xAxis = new Plottable.Axis.Time(xScale, "bottom");
          yAxis = new Plottable.Axis.Numeric(yScale, "left");
          addY = function(d) {
            return d.y0 + d.y;
          };
          area_existing = new Plottable.Plot.Area(existingUsersData, xScale, yScale).project("x", "date", xScale).project("y0", "y0", yScale).project("y", addY, yScale).classed("existing-users", true);
          area_new = new Plottable.Plot.Area(newUsersData, xScale, yScale).project("x", "date", xScale).project("y0", "y0", yScale).project("y", addY, yScale).classed("new-users", true);
          gridlines = new Plottable.Component.Gridlines(xScale, yScale);
          legend = new Plottable.Component.Legend(colorScale);
          center = area_existing.merge(area_new).merge(gridlines);
          chart = new Plottable.Component.Table([[null, legend], [yAxis, center], [null, xAxis]]);
          chart.renderTo("#users-chart");
        };
        bChartUserData.then(render);
      }
    };
  }]);

}).call(this);
