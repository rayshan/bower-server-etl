(function() {
  var module;

  module = angular.module('B.Chart.Users', []);

  module.service('bChartUserData', ["$q", "bDataSvc", "d3", function($q, bDataSvc, d3) {
    var parseData;
    parseData = function(data) {
      var parseDate, _deferred;
      _deferred = $q.defer();
      data = data.data.users;
      parseDate = d3.time.format("%Y%m%d").parse;
      data.forEach(function(d) {
        d[1] = parseDate(d[1]);
      });
      data = d3.nest().key(function(d) {
        return d[0];
      }).entries(data);
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
            return d.values;
          }).x(function(d) {
            return d[1];
          }).y(function(d) {
            return d[2];
          }).order("reverse");
          usersData = data.data.slice(0, 2);
          npmData = data.data[2];
          stackedData = stack(usersData);
          newUsersData = stackedData[0].values;
          existingUsersData = stackedData[1].values;
          xScale = new Plottable.Scale.Time();
          yScale = new Plottable.Scale.Linear();
          colorScale = new Plottable.Scale.Color().domain(["New Users", "Existing Users"]).range(["#00acee", "#ffcc2f"]);
          xAxis = new Plottable.Axis.Time(xScale, "bottom");
          yAxis = new Plottable.Axis.Numeric(yScale, "left");
          addY = function(d) {
            return d.y0 + d.y;
          };
          area_existing = new Plottable.Plot.Area(existingUsersData, xScale, yScale).project("x", "1", xScale).project("y0", "y0", yScale).project("y", addY, yScale).project("fill-opacity", 1).project("fill", function() {
            return "#ffcc2f";
          });
          area_new = new Plottable.Plot.Area(newUsersData, xScale, yScale).project("x", "1", xScale).project("y0", "y0", yScale).project("y", addY, yScale).project("fill", function() {
            return "#00acee";
          }).project("fill-opacity", 1);
          gridlines = new Plottable.Component.Gridlines(xScale, yScale);
          legend = new Plottable.Component.Legend(colorScale);
          center = gridlines.merge(area_existing).merge(area_new).merge(legend);
          chart = new Plottable.Template.StandardChart().center(center).xAxis(xAxis).yAxis(yAxis);
          chart.renderTo("#users-chart");
        };
        bChartUserData.then(render);
      }
    };
  }]);

}).call(this);
