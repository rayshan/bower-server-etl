(function() {
  var module;

  module = angular.module('B.Chart.Users', []);

  module.service('bChartUserData', ["$q", "bDataSvc", "d3", function($q, bDataSvc, d3) {
    var parseData;
    parseData = function(data) {
      var maxUsers, maxUsersDayI, parseDate, totalUsersByDay, _deferred;
      _deferred = $q.defer();
      data = data.data.users;
      parseDate = d3.time.format("%Y%m%d").parse;
      data.forEach(function(d) {
        d[1] = parseDate(d[1]);
      });
      data = d3.nest().key(function(d) {
        return d[0];
      }).entries(data);
      totalUsersByDay = data[0].values.map(function(ele, i, arr) {
        return {
          day: arr[i][1],
          users: ele[2] + data[1].values[i][2]
        };
      });
      maxUsers = d3.max(totalUsersByDay, function(d) {
        return d.users;
      });
      maxUsersDayI = null;
      totalUsersByDay.filter(function(ele, i) {
        return ele.users === maxUsers && (maxUsersDayI = i);
      });
      _deferred.resolve({
        data: data,
        maxUsers: maxUsers,
        maxUsersDayI: maxUsersDayI
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
          var area, canvas, h, hOrig, legend, margin, marginBase, stack, svg, users, w, wOrig, x, xAxis, y, yAxis;
          canvas = ele[0].querySelector(".b-chart.b-users").children[0];
          wOrig = ele.children()[1].clientWidth;
          hOrig = ele.children()[1].clientHeight;
          marginBase = 30;
          margin = {
            t: marginBase * 1.5,
            l: marginBase * 1.5,
            r: marginBase,
            b: marginBase
          };
          w = wOrig - margin.l - margin.r;
          h = hOrig - margin.t - margin.b;
          x = d3.time.scale().range([0, w]).domain(d3.extent(data.data[1].values, function(d) {
            return d[1];
          }));
          y = d3.scale.linear().range([h, 0]).domain([0, data.maxUsers]);
          xAxis = d3.svg.axis().scale(x).ticks(d3.time.weeks).orient("bottom");
          yAxis = d3.svg.axis().scale(y).orient("left").ticks(6).tickSize(-w, 0);
          area = d3.svg.area().x(function(d) {
            return x(d[1]);
          }).y0(function(d) {
            return y(d.y0);
          }).y1(function(d) {
            return y(d.y0 + d.y);
          }).interpolate("cardinal");
          stack = d3.layout.stack().values(function(d) {
            return d.values;
          }).x(function(d) {
            return d[1];
          }).y(function(d) {
            return d[2];
          }).order("reverse");
          svg = d3.select(canvas).attr("width", w + margin.l + margin.r).attr("height", h + margin.t + margin.b).append("g").attr("transform", "translate(" + margin.l + ", " + margin.t + ")");
          users = svg.selectAll(".users").data(stack(data.data)).enter().append("g").attr("class", function(d) {
            return "users " + d.key;
          });
          users.append("path").attr("class", "area").attr("d", function(d) {
            return area(d.values);
          }).attr("data-legend", function(d) {
            return d.key;
          });
          users.selectAll("text").data(function(d) {
            return d.values.filter(function(ele, i) {
              return i === data.maxUsersDayI;
            });
          }).enter().append("text").attr("x", function(d) {
            return x(d[1]);
          }).attr("y", function(d) {
            return y(d.y + d.y0);
          }).attr("transform", "translate(0, -15)").text(function(d) {
            return d3.format('0,000')(d[2]);
          });
          users.selectAll("circle").data(function(d) {
            return d.values.filter(function(ele, i) {
              return i === data.maxUsersDayI;
            });
          }).enter().append("circle").attr("cx", function(d) {
            return x(d[1]);
          }).attr("cy", function(d) {
            return y(d.y + d.y0);
          }).attr("r", "0.4em");
          svg.append("g").attr("class", "axis x").attr("transform", "translate(0, " + h + ")").call(xAxis);
          svg.append("g").attr("class", "axis y").call(yAxis);
          legend = svg.append("g").attr("class", "legend").attr("transform", "translate(0, " + (-marginBase / 2) + ")").call(d3.legend);
        };
        bChartUserData.then(render);
      }
    };
  }]);

}).call(this);
