// Generated by CoffeeScript 1.7.1
(function() {
  var module;

  module = angular.module('B.Chart.Users', []);

  module.directive("bChartUsers", function(d3, bGaSvc) {
    return {
      templateUrl: 'b-chart-users/partial.html',
      restrict: 'E',
      link: function(scope, ele) {
        var render;
        render = function(data) {
          var area, canvas, h, hOrig, legend, margin, marginBase, maxUsers, maxUsersDayI, minUsers, minUsersDayI, parseDate, stack, svg, totalUsersByDay, users, w, wOrig, x, xAxis, y;
          parseDate = d3.time.format("%Y%m%d").parse;
          data.forEach(function(d) {
            d[1] = parseDate(d[1]);
            d[2] = +d[2];
          });
          data = d3.nest().key(function(d) {
            return d[0];
          }).entries(data);
          totalUsersByDay = data[0].values.map(function(ele, i, arr) {
            var res;
            return res = {
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
          minUsers = d3.min(totalUsersByDay, function(d) {
            return d.users;
          });
          minUsersDayI = null;
          totalUsersByDay.filter(function(ele, i) {
            return ele.users === minUsers && (minUsersDayI = i);
          });
          canvas = ele[0].querySelector(".b-chart.b-users").children[0];
          wOrig = d3.select(canvas).node().offsetWidth;
          hOrig = d3.select(canvas).node().offsetHeight;
          marginBase = 30;
          margin = {
            t: marginBase,
            l: marginBase,
            r: marginBase,
            b: marginBase
          };
          w = wOrig - margin.l - margin.r;
          h = hOrig - margin.t - margin.b;
          x = d3.time.scale().range([0, w]).domain(d3.extent(data[1].values, function(d) {
            return d[1];
          }));
          y = d3.scale.linear().range([h, 0]).domain([0, maxUsers]);
          xAxis = d3.svg.axis().scale(x).orient("bottom");
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
          svg = d3.select(canvas).append("svg").attr("width", w + margin.l + margin.r).attr("height", h + margin.t + margin.b).append("g").attr("transform", "translate(" + margin.l + ", " + margin.t + ")");
          users = svg.selectAll(".users").data(stack(data)).enter().append("g").attr("class", function(d) {
            return "users " + d.key;
          });
          users.append("path").attr("class", "area").attr("d", function(d) {
            return area(d.values);
          }).attr("data-legend", function(d) {
            return d.key;
          });
          users.selectAll("text").data(function(d) {
            return d.values.filter(function(ele, i) {
              return i === maxUsersDayI || i === minUsersDayI;
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
              return i === maxUsersDayI || i === minUsersDayI;
            });
          }).enter().append("circle").attr("cx", function(d) {
            return x(d[1]);
          }).attr("cy", function(d) {
            return y(d.y + d.y0);
          }).attr("r", "0.4em");
          svg.append("g").attr("class", "axis x").attr("transform", "translate(0, " + h + ")").call(xAxis);
          legend = svg.append("g").attr("class", "legend").call(d3.legend);
        };
        bGaSvc.fetch.then(render);
      }
    };
  });

}).call(this);

//# sourceMappingURL=module.map
