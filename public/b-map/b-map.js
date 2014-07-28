(function() {
  var module;

  module = angular.module('B.Map', []);

  module.factory('topojson', function() {
    return topojson;
  });

  module.factory('bTopojsonSvc', ["$http", function($http) {
    return $http.get('dist/ne_110m_admin_0_countries_topojson.json');
  }]);

  module.factory('d3map', ["d3", function(d3) {
    d3.collision = function(alpha, nodes, radiusKey, bubblePadding, w, h) {
      var quadtree;
      radiusKey = 'r' + radiusKey;
      quadtree = d3.geom.quadtree(nodes);
      return function(node) {
        var nr, nx1, nx2, ny1, ny2;
        nr = node[radiusKey] + bubblePadding;
        nx1 = node.x - nr;
        nx2 = node.x + nr;
        ny1 = node.y - nr;
        ny2 = node.y + nr;
        return quadtree.visit(function(quad, x1, y1, x2, y2) {
          var l, r, x, y;
          if (quad.point && (quad.point !== node)) {
            x = node.x - quad.point.x;
            y = node.y - quad.point.y;
            l = Math.sqrt(x * x + y * y);
            r = nr + quad.point[radiusKey];
            if (l < r) {
              l = (l - r) / l * alpha;
              node.x -= x *= l;
              node.y -= y *= l;
              quad.point.x += x;
              quad.point.y += y;
            }
          }
          return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
        });
      };
    };
    return d3;
  }]);

  module.factory('bMapDataSvc', ["$filter", "$q", "d3map", "topojson", "bDataSvc", "bTopojsonSvc", function($filter, $q, d3map, topojson, bDataSvc, bTopojsonSvc) {
    var parseData;
    parseData = function(data) {
      var colorsDensity, colorsUsers, countryData, countryDataTopo, maxDensity, maxUsers, minDensity, radiusDensity, radiusUsers, topo, topojsonData, _deferred;
      _deferred = $q.defer();
      countryData = data[0].data.geo;
      topojsonData = data[1].data;
      maxUsers = d3map.max(countryData, function(country) {
        return country.users;
      });
      maxDensity = d3map.max(countryData, function(country) {
        return country.density;
      });
      minDensity = d3map.min(countryData, function(country) {
        return country.density;
      });
      colorsUsers = d3.scale.log().domain([2, maxUsers]).range(["#00acee", "#EF5734"]);
      colorsDensity = d3map.scale.log().domain([minDensity, maxDensity]).range(["#00acee", "#EF5734"]);
      radiusUsers = d3map.scale.sqrt().domain([2, maxUsers]).range([2, 55]);
      radiusDensity = d3map.scale.sqrt().domain([minDensity, maxDensity]).range([2, 55]);
      topo = topojson.feature(topojsonData, topojsonData.objects.countries);
      countryDataTopo = topo.features.filter(function(d) {
        return countryData.some(function(country) {
          return country.isoCode === d.id;
        });
      }).map(function(d) {
        var bowerData;
        bowerData = $filter('filter')(countryData, {
          isoCode: d.id
        })[0];
        d.data = bowerData;
        d.rDensity = bowerData ? radiusDensity(bowerData.density) : 0;
        d.rUsers = bowerData ? radiusUsers(bowerData.users) : 0;
        return d;
      });
      _deferred.resolve({
        topo: topo,
        topojsonData: topojsonData,
        colorsUsers: colorsUsers,
        colorsDensity: colorsDensity,
        radiusUsers: radiusUsers,
        radiusDensity: radiusDensity,
        countryDataTopo: countryDataTopo
      });
      return _deferred.promise;
    };
    return $q.all([bDataSvc.fetchAllP, bTopojsonSvc]).then(parseData);
  }]);

  module.directive("bMap", ["d3map", "topojson", "bMapDataSvc", "$window", function(d3map, topojson, bMapDataSvc, $window) {
    return {
      templateUrl: 'b-map/b-map.html',
      restrict: 'E',
      link: function(scope, ele) {
        var bubbleOverBorder, bubblePadding, bubbleRBreaks, canvas, force, gravity, h, path, projection, render, svg, tick, transitionDuration, w;
        tick = null;
        scope.chartType = "Density";
        scope.zoomed = false;
        scope.$watch('chartType', function(chartType, chartTypeOld) {
          var radiusKey;
          if (chartType !== chartTypeOld) {
            radiusKey = 'r' + chartType;
            svg.selectAll(".label").text(function(d) {
              if (d[radiusKey] >= bubbleRBreaks.sm) {
                return d.data.isoCode;
              }
            }).attr("class", "label").classed("sm", function(d) {
              return d[radiusKey] <= bubbleRBreaks.md;
            }).classed("md", function(d) {
              return d[radiusKey] > bubbleRBreaks.md && d[radiusKey] <= bubbleRBreaks.lg;
            }).classed("lg", function(d) {
              return d[radiusKey] > bubbleRBreaks.lg;
            });
            svg.selectAll(".bubble").transition().duration(transitionDuration).attr("r", function(d) {
              return d[radiusKey];
            }).attr("fill", function(d) {
              return scope.data["colors" + chartType](d.data[chartType.toLowerCase()]);
            });
            force.start();
          }
        });
        bubblePadding = 1;
        bubbleOverBorder = 5;
        bubbleRBreaks = {
          sm: 10,
          md: 15,
          lg: 20
        };
        transitionDuration = 250;
        canvas = ele[0].querySelector(".b-map");
        w = canvas.clientWidth;
        h = canvas.clientHeight;
        svg = d3map.select(canvas).append("svg").attr("width", w).attr("height", h);
        projection = d3map.geo.equirectangular().scale(160).translate([w / 2.1, h / 1.55]);
        path = d3map.geo.path().projection(projection);
        force = d3map.layout.force().gravity(0).size([w * 2, h * 2]);
        gravity = function(k) {
          return function(d) {
            d.x += (d.x0 - d.x) * k;
            return d.y += (d.y0 - d.y) * k;
          };
        };
        render = function(data) {
          var countries, countryBubbles, countryContainer, countryLabels, fitScreen, landContainer, zoom;
          scope.data = data;
          data.countryDataTopo = data.countryDataTopo.map(function(d) {
            var centroid;
            centroid = path.centroid(d.geometry);
            d.x = centroid[0];
            d.y = centroid[1];
            d.x0 = centroid[0];
            d.y0 = centroid[1];
            return d;
          });
          landContainer = svg.append("g").attr("class", "container land");
          landContainer.append("path").datum(data.topo).attr("class", "land").attr("d", path);
          landContainer.append("path").datum(topojson.mesh(data.topojsonData, data.topojsonData.objects.countries, function(a, b) {
            return a !== b;
          })).attr("class", "country-boundary").attr("d", path);
          countryContainer = svg.append("g").attr("class", "container countries");
          countries = countryContainer.selectAll("g").data(data.countryDataTopo).enter().append("g").attr("class", "country").attr("id", function(d) {
            return d.data.isoCode;
          });
          countryBubbles = countries.append("circle").attr("class", "bubble").attr("r", function(d) {
            return d.rDensity;
          }).attr("fill", function(d) {
            return data.colorsDensity(d.data.density);
          });
          countryLabels = countries.append("text").text(function(d) {
            if (d.rDensity >= bubbleRBreaks.sm) {
              return d.data.isoCode;
            }
          }).attr("class", "label").classed("sm", function(d) {
            return d.rDensity <= bubbleRBreaks.md;
          }).classed("md", function(d) {
            return d.rDensity > bubbleRBreaks.md && d.rDensity <= bubbleRBreaks.lg;
          }).classed("lg", function(d) {
            return d.rDensity > bubbleRBreaks.lg;
          });
          zoom = function() {
            var k, x, y;
            if (!scope.zoomed) {
              x = d3map.mouse(this)[0];
              y = d3map.mouse(this)[1];
              k = 3;
              scope.zoomed = true;
            } else {
              x = w / 2;
              y = h / 2;
              k = 1;
              scope.zoomed = false;
            }
            landContainer.transition().duration(750).attr("transform", "translate(" + w / 2 + "," + h / 2 + ")scale(" + k + ")translate(" + -x + "," + -y + ")").style("stroke-width", 1.5 / k + "px");
            countryContainer.transition().duration(750).attr("transform", "translate(" + w / 2 + "," + h / 2 + ")scale(" + k + ")translate(" + -x + "," + -y + ")").style("stroke-width", 1.5 / k + "px");
          };
          landContainer.selectAll("path").on("click", zoom);
          countryContainer.selectAll("g").on("click", zoom);
          fitScreen = function() {
            w = canvas.clientWidth;
            d3map.selectAll("svg").attr("width", w).attr("height", h);
            d3map.behavior.zoom().center([w / 2, h / 2]);
          };
          $window.onresize = function() {
            return fitScreen();
          };
          tick = function(e) {
            var radiusKey;
            radiusKey = 'r' + scope.chartType;
            countryBubbles.each(gravity(e.alpha * .1)).each(d3map.collision(.2, scope.data.countryDataTopo, scope.chartType, bubblePadding)).attr("cx", function(d) {
              return Math.max(d[radiusKey], (Math.min(w - d[radiusKey], d.x)) + bubbleOverBorder);
            }).attr("cy", function(d) {
              return Math.max(d[radiusKey] - bubbleOverBorder, Math.min(h - d[radiusKey], d.y));
            });
            countryLabels.attr("x", function(d) {
              return Math.max(d[radiusKey], (Math.min(w - d[radiusKey], d.x)) + bubbleOverBorder);
            }).attr("y", function(d) {
              var res;
              res = Math.max(d[radiusKey] - bubbleOverBorder, Math.min(h - d[radiusKey], d.y));
              if (d[radiusKey] <= bubbleRBreaks.md) {
                return res + 3;
              } else if (d[radiusKey] > bubbleRBreaks.md && d[radiusKey] <= bubbleRBreaks.lg) {
                return res + 4;
              } else {
                return res + 6;
              }
            });
          };
          force.nodes(countryBubbles[0]).on("tick", tick).start();
        };
        bMapDataSvc.then(render);
      }
    };
  }]);

}).call(this);
