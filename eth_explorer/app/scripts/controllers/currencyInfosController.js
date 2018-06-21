angular.module('ethExplorer')
    .controller('currencyInfosCtrl', function ($rootScope, $scope, $location) {
        $scope.init = function () {
            $scope.tokens = $rootScope.loadERC20list("CurrencyToken");
        };
        $scope.init();
    });
