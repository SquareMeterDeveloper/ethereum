'use strict';

angular.module('ethExplorer', ['ngRoute', 'ui.bootstrap'])
    .config(['$routeProvider',
        function ($routeProvider) {
            $routeProvider.when('/', {
                templateUrl: 'views/main.html',
                controller: 'mainCtrl'
            }).when('/currencyInfos/', {
                templateUrl: 'views/currencyInfos.html',
                controller: 'currencyInfosCtrl'
            }).when('/currency/:addressId', {
                templateUrl: 'views/currencyDetail.html',
                controller: 'currencyDetailCtrl'
            }).when('/token/:address?account=:account', {
                controller: 'tokenCtrl'
            }).when('/assetInfos/', {
                templateUrl: 'views/assetInfos.html',
                controller: 'assetInfosCtrl'
            }).when('/asset/:addressId', {
                templateUrl: 'views/assetDetail.html',
                controller: 'assetDetailCtrl'
            }).when('/block/:blockId', {
                templateUrl: 'views/blockInfos.html',
                controller: 'blockInfosCtrl'
            }).when('/transaction/:transactionId', {
                templateUrl: 'views/transactionInfos.html',
                controller: 'transactionInfosCtrl'
            }).when('/address/:addressId', {
                templateUrl: 'views/addressInfo.html',
                controller: 'addressInfoCtrl'
            }).otherwise({
                redirectTo: '/'
            });
        }])
    .run(function ($rootScope) {
        var web3 = new Web3();
        var eth_node_url = 'http://47.100.197.28:8545'; // TODO: remote URL
        web3.setProvider(new web3.providers.HttpProvider(eth_node_url));
        $rootScope.web3 = web3;
        $rootScope.feicode = new Feicode();
        $rootScope.naming = "0x70f9852a90f16faa789c94cf918786142bff59c4";
        $rootScope.namingAbi = [{
            "constant": false,
            "inputs": [{"name": "_newOperator", "type": "address"}],
            "name": "changeOperator",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "name", "type": "string"}, {"name": "key", "type": "uint256"}, {
                "name": "adr",
                "type": "address"
            }],
            "name": "setContract",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [],
            "name": "getOwner",
            "outputs": [{"name": "", "type": "address"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "name", "type": "string"}, {"name": "key", "type": "uint256"}],
            "name": "getContract",
            "outputs": [{"name": "", "type": "address"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [],
            "name": "getOperator",
            "outputs": [{"name": "", "type": "address"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "_newOwner", "type": "address"}],
            "name": "transferOwnership",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "name", "type": "string"}],
            "name": "getContracts",
            "outputs": [{"name": "", "type": "address[]"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "anonymous": false,
            "inputs": [{"indexed": true, "name": "sender", "type": "address"}, {
                "indexed": false,
                "name": "name",
                "type": "string"
            }, {"indexed": true, "name": "key", "type": "uint256"}, {
                "indexed": false,
                "name": "adr",
                "type": "address"
            }, {"indexed": false, "name": "code", "type": "uint256"}],
            "name": "SetContract",
            "type": "event"
        }, {
            "anonymous": false,
            "inputs": [{"indexed": true, "name": "from", "type": "address"}, {
                "indexed": true,
                "name": "to",
                "type": "address"
            }],
            "name": "ChangeOperator",
            "type": "event"
        }, {
            "anonymous": false,
            "inputs": [{"indexed": true, "name": "from", "type": "address"}, {
                "indexed": true,
                "name": "to",
                "type": "address"
            }],
            "name": "TransferOwnership",
            "type": "event"
        }];
        $rootScope.abi20 = [{
            "constant": false,
            "inputs": [{"name": "_newOperator", "type": "address"}],
            "name": "changeOperator",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "to", "type": "address"}, {"name": "value", "type": "uint256"}, {
                "name": "data",
                "type": "uint256"
            }],
            "name": "transfer",
            "outputs": [{"name": "success", "type": "bool"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "to", "type": "address"}, {"name": "value", "type": "uint256"}],
            "name": "approve",
            "outputs": [{"name": "ok", "type": "bool"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [],
            "name": "totalSupply",
            "outputs": [{"name": "_totalSupply", "type": "uint256"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "index", "type": "uint256"}],
            "name": "holderAt",
            "outputs": [{"name": "adr", "type": "address"}, {"name": "balance", "type": "uint256"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "from", "type": "address"}, {"name": "to", "type": "address"}, {
                "name": "value",
                "type": "uint256"
            }],
            "name": "transferFrom",
            "outputs": [{"name": "success", "type": "bool"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [],
            "name": "decimals",
            "outputs": [{"name": "_decimals", "type": "uint256"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [],
            "name": "holdersCount",
            "outputs": [{"name": "count", "type": "uint256"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [{"name": "tokenOwner", "type": "address"}],
            "name": "balanceOf",
            "outputs": [{"name": "balance", "type": "uint256"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [],
            "name": "holders",
            "outputs": [{"name": "_holders", "type": "address[]"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [],
            "name": "getOwner",
            "outputs": [{"name": "", "type": "address"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [],
            "name": "symbol",
            "outputs": [{"name": "_symbol", "type": "string"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "to", "type": "address"}, {"name": "value", "type": "uint256"}],
            "name": "transfer",
            "outputs": [{"name": "success", "type": "bool"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [{"name": "tokenOwner", "type": "address"}, {"name": "spender", "type": "address"}],
            "name": "allowance",
            "outputs": [{"name": "_remaining", "type": "uint256"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": true,
            "inputs": [],
            "name": "getOperator",
            "outputs": [{"name": "", "type": "address"}],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "_newOwner", "type": "address"}],
            "name": "transferOwnership",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "constant": false,
            "inputs": [{"name": "from", "type": "address"}, {"name": "to", "type": "address"}, {
                "name": "value",
                "type": "uint256"
            }, {"name": "data", "type": "uint256"}],
            "name": "transferFrom",
            "outputs": [{"name": "success", "type": "bool"}],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }, {
            "anonymous": false,
            "inputs": [{"indexed": true, "name": "from", "type": "address"}, {
                "indexed": true,
                "name": "to",
                "type": "address"
            }, {"indexed": true, "name": "data", "type": "uint256"}, {
                "indexed": false,
                "name": "value",
                "type": "uint256"
            }, {"indexed": false, "name": "code", "type": "uint256"}],
            "name": "Transfer",
            "type": "event"
        }, {
            "anonymous": false,
            "inputs": [{"indexed": true, "name": "from", "type": "address"}, {
                "indexed": true,
                "name": "to",
                "type": "address"
            }, {"indexed": false, "name": "value", "type": "uint256"}, {
                "indexed": false,
                "name": "code",
                "type": "uint256"
            }],
            "name": "Approve",
            "type": "event"
        }, {
            "anonymous": false,
            "inputs": [{"indexed": true, "name": "from", "type": "address"}, {
                "indexed": true,
                "name": "to",
                "type": "address"
            }],
            "name": "ChangeOperator",
            "type": "event"
        }, {
            "anonymous": false,
            "inputs": [{"indexed": true, "name": "from", "type": "address"}, {
                "indexed": true,
                "name": "to",
                "type": "address"
            }],
            "name": "TransferOwnership",
            "type": "event"
        }];

        $rootScope.callContract = function (params) {
            var contractInstance = web3.eth.contract(params.abi).at(params.contract);
            var arr = params.params;
            var method = params.method;
            return arr.length > 0 ? contractInstance[method]["call"].apply(this, arr) : contractInstance[method].call();
        };

        $rootScope.loadERC20list = function (name) {
            var addresses = $rootScope.callContract({
                abi: $rootScope.namingAbi,
                contract: $rootScope.naming,
                method: "getContracts",
                params: [name]
            });
            var arr20 = [];
            for (var i = 0; i < addresses.length; i++) {
                var address = addresses[i];
                var symbol = $rootScope.callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [],
                    method: "symbol"
                });
                var totalSupply = parseInt($rootScope.callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [],
                    method: "totalSupply"
                }));
                var count = parseInt($rootScope.callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [],
                    method: "holdersCount"
                }));
                arr20.push({
                    address: address,
                    symbol: symbol,
                    totalSupply: totalSupply,
                    count: count
                });
            }
            return arr20;
        };

        $rootScope.loadERC20 = function (address) {
            var symbol = $rootScope.callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "symbol"
            });

            var totalSupply = parseInt($rootScope.callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "totalSupply"
            }));

            var count = parseInt($rootScope.callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "holdersCount"
            }));

            var holdersAddresses = $rootScope.callContract({
                contract: address,
                abi: $rootScope.abi20,
                params: [],
                method: "holders"
            });

            var holders = [];
            for (var i = 0; i < holdersAddresses.length; i++) {
                var holder = holdersAddresses[i];
                var balance = $rootScope.callContract({
                    contract: address,
                    abi: $rootScope.abi20,
                    params: [holder],
                    method: "balanceOf"
                });
                holders.push({
                    holder: holder,
                    balance: parseInt(balance)
                });
            }
            return {
                symbol: symbol,
                totalSupply: totalSupply,
                count: count,
                holders: holders
            };
        };

        function sleepFor(sleepDuration) {
            var now = new Date().getTime();
            while (new Date().getTime() < now + sleepDuration) { /* do nothing */
            }
        }

        var connected = false;
        if (!web3.isConnected()) {
            $('#connectwarning').modal({keyboard: false, backdrop: 'static'})
            $('#connectwarning').modal('show')
        }

    });
