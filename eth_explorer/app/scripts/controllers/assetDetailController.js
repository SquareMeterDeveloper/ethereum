angular.module('ethExplorer')
    .controller('assetDetailCtrl', function ($rootScope, $scope, $routeParams, $location) {
        var web3 = $rootScope.web3;
        $scope.init = function () {
            var address = $routeParams.addressId;
            $scope.token = $rootScope.loadERC20(address);
            $scope.query = function () {
                var account = ($scope.account == null || $scope.account === "") ? "0xFFFFFFFFFFFFFFF" : $scope.account;
                var contractInstance = web3.eth.contract($rootScope.abi20).at($scope.address);
                var eventFrom = contractInstance["Transfer"]({from: account}, {fromBlock: 0, toBlock: 'latest'});
                eventFrom.get(function (e, log) {
                    if (e) {
                    }
                    else {
                        $scope.logsFrom = [];
                        for (var i = 0; i < log.length; i++) {
                            var arg = log[i].args;
                            $scope.logsFrom.push(convertArgs(arg));
                        }
                        $scope.$apply();
                    }
                });
                var eventTo = contractInstance["Transfer"]({to: account}, {fromBlock: 0, toBlock: 'latest'});
                eventTo.get(function (e, log) {
                    if (e) {
                    }
                    else {
                        $scope.logsTo = [];
                        for (var i = 0; i < log.length; i++) {
                            var arg = log[i].args;
                            $scope.logsTo.push(convertArgs(arg));
                        }
                        $scope.$apply();
                    }
                });
            };

            function convertArgs(arg) {
                return {
                    from: arg.from,
                    to: arg.to,
                    value: parseInt(arg.value),
                    data: $rootScope.feicode.feicodeDecode(web3.toBigNumber(arg.data).toString(10))
                };
            }
        };
        $scope.init();
    })
;
