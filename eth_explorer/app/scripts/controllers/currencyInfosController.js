angular.module('ethExplorer')
    .controller('currencyInfosCtrl', function ($rootScope, $scope, $location) {
        var web3 = $rootScope.web3;
        $scope.init = function () {
            var addresses = callContract({
                abi: $rootScope.namingAbi,
                contract: $rootScope.naming,
                method: "getContract",
                params: ["CurrencyToken"]
            });
            $scope.currencies = [];
            for (var i = 0; i < addresses.length; i++) {
                var address = addresses[i];
                var symbol = callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [],
                    method: "symbol"
                });
                var totalSupply = parseInt(callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [],
                    method: "totalSupply"
                })) / 1000000.0;
                var count = parseInt(callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [],
                    method: "holdersCount"
                }));
                $scope.currencies.push({
                    address: address,
                    symbol: symbol,
                    totalSupply: totalSupply,
                    count: count
                });
            }

            function callContract(params) {
                var contractInstance = web3.eth.contract(params.abi).at(params.contract);
                var arr = params.params;
                var method = params.method;
                return arr.length > 0 ? contractInstance[method]["call"].apply(this, arr) : contractInstance[method].call();
            }
        };
        $scope.init();
    });
