angular.module('ethExplorer')
    .controller('assetInfosCtrl', function ($rootScope, $scope, $location) {
        $scope.init = function () {
            $scope.tokens = $rootScope.loadERC20list("AssetToken")
        };
        $scope.init();
    });
