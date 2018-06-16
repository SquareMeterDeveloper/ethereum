angular.module('ethExplorer')
    .controller('currencyDetailCtrl', function ($rootScope, $scope, $routeParams, $location) {
        var web3 = $rootScope.web3;
        $scope.init = function () {
            var address = $routeParams.addressId;
            $scope.address = address;
            $scope.symbol = callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "symbol"
            });

            $scope.totalSupply = parseInt(callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "totalSupply"
            })) / 1000000.0;

            $scope.count = parseInt(callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "holdersCount"
            }));

            var holders = callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "holders"
            });
            $scope.holders = [];
            for (var i = 0; i < holders.length; i++) {
                var holder = holders[i];
                var balance = callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [holder],
                    method: "balanceOf"
                }) / 1000000.0;
                $scope.holders.push({
                    holder: holder,
                    balance: balance
                });
            }

            $scope.query = function () {
                var account = ($scope.account == null || $scope.account == "") ? "0xFFFFFFFFFFFFFFF" : $scope.account;
                var contractInstance = web3.eth.contract($rootScope.abi20).at($scope.address);
                var eventFrom = contractInstance["Transfer"]({from: account}, {fromBlock: 0, toBlock: 'latest'});
                eventFrom.get(function (e, log) {
                    if (e) {

                    }
                    else {
                        $scope.logsFrom = [];
                        for (var i = 0; i < log.length; i++) {
                            $scope.logsFrom.push(log[i].args);
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
                            $scope.logsTo.push(log[i].args);
                        }
                        $scope.$apply();
                    }
                });
            };


            function callContract(params) {
                var contractInstance = web3.eth.contract(params.abi).at(params.contract);
                var arr = params.params;
                var method = params.method;
                return arr.length > 0 ? contractInstance[method]["call"].apply(this, arr) : contractInstance[method].call();
            }
        };
        $scope.init();
        $scope.processRequest = function () {
            alert($scope.address);
            alert($scope.account);
        };
    })
;
