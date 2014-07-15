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
            pkgObj.installsSum = bPoP.process(pkgObj.installs, 7);
          });
          scope.packages = data.data.packages;
        });
        scope.hideAngular = true;
        scope.toggleHideAngular = function() {
          scope.hideAngular = !scope.hideAngular;
        };
      }
    };
  }]);

}).call(this);
