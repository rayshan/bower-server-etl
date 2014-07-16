(function() {
  var module;

  module = angular.module('B.Table.Pkgs', []);

  module.directive("bTablePkgs", ["bDataSvc", "bPoP", function(bDataSvc, bPoP) {
    return {
      templateUrl: 'b-table-pkgs/b-table-pkgs.html',
      restrict: 'E',
      link: function(scope) {
        var reduceFunc;
        reduceFunc = function(period, currentOrPrior) {
          return function(a, b, i) {
            if ((currentOrPrior === 'current' ? i >= period : i < period)) {
              return a + b;
            } else {
              return a;
            }
          };
        };
        bDataSvc.fetchAllP.then(function(data) {
          data.data.packages.forEach(function(pkgObj) {
            pkgObj.priorRank = pkgObj.rank[0];
            pkgObj.currentRank = pkgObj.rank[1];
            pkgObj.rankVelocity = pkgObj.currentRank - pkgObj.priorRank;
            pkgObj.installsSum = bPoP.process(pkgObj.installs, 7);
            pkgObj.currentInstallsSum = pkgObj.installsSum[1];
          });
          scope.packages = data.data.packages;
        });
        scope.setPredicate = function(predicate) {
          if (scope.predicate !== predicate) {
            scope.reverse = false;
          } else {
            scope.reverse = !scope.reverse;
          }
          scope.predicate = predicate;
        };
        scope.checkPredicate = function(predicate, reverse) {
          return scope.predicate === predicate && (reverse === void 0 || reverse);
        };
        scope.setPredicate('currentRank');
        scope.hideAngular = true;
        scope.toggleHideAngular = function() {
          scope.hideAngular = !scope.hideAngular;
        };
      }
    };
  }]);

  module.filter('predicateFilter', function() {
    return function(items, predicate) {
      var filtered, item, _i, _len;
      predicate = predicate.replace('-', '');
      filtered = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        if (item[predicate] != null) {
          filtered.push(item);
        }
      }
      return filtered;
    };
  });

}).call(this);
