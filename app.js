'use strict';
var express = require('express');
var Promise = require('bluebird');
var ipfsAPI = require('ipfs-api');
var fs = require('fs');
var Web3 = require('web3');
var web3Admin = require('web3admin');
var keythereum = require('keythereum');
var Tx = require('ethereumjs-tx');
var util = require('ethereumjs-util');
var bodyParser = require('body-parser');
var ipfs = ipfsAPI('/ip4/127.0.0.1/tcp/5001');
var web3;
if (typeof web3 !== 'undefined') {
    web3 = new Web3(web3.currentProvider);
} else {
    web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
}
web3Admin.extend(web3);
var app = new express();
app.use(bodyParser.json());
app.all('*', function (req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin,X-Requested-With, Content-Type, Accept");
    res.header("Access-Control-Allow-Methods", "PUT,POST,GET,DELETE,OPTIONS");
    res.header("X-Powered-By", ' 3.2.1')
    res.header("Content-Type", "application/json;charset=utf-8");
    next();
});
app.get('/', function (req, res) {
    res.send("Ethereum Api");
});

function isValidAddress(address) {
    return address != null && (address.indexOf('0x' >= 0 ? address.length === 42 : address.length === 40));
}

function prepareParameters(req, options) {
    return new Promise(function (resolve, reject) {
        try {
            var verify = {};
            var input = {};
            var jsonAbi;
            if (options.privateKey) {
                if (req.body.privateKey == null || req.body.privateKey === "") {
                    verify.flag = true;
                    verify.privateKey = "私钥无效";
                } else {
                    input.privateKey = req.body.privateKey;
                }
            }
            if (options.abi) {
                if (req.body.abi == null || req.body.abi === "") {
                    verify.flag = true;
                    verify.abi = "合约ABI不能为空";
                }
                else {
                    jsonAbi = JSON.parse(req.body.abi);
                    if (jsonAbi == null) {
                        verify.flag = true;
                        verify.abi = "无效的ABI";
                    } else {
                        input.abi = jsonAbi;
                    }
                }
            }
            if (options.data) {
                if (req.body.data == null || req.body.data === "") {
                    verify.flag = true;
                    verify.data = "合约代码不能为空";
                } else {
                    input.data = req.body.data;
                }
            }
            if (options.contract) {
                if (!isValidAddress(req.body.contract)) {
                    verify.flag = true;
                    verify.contract = "合约地址无效";
                }
                else {
                    input.contract = req.body.contract.indexOf('0x') >= 0 ? req.body.contract : '0x' + req.body.contract;
                }
            }
            if (options.method) {
                if (req.body.method == null || req.body.method === "") {
                    verify.flag = true;
                    verify.method = "合约函数名不能为空";
                } else {
                    input.method = req.body.method;
                }
            }
            if (options.eventName) {
                if (req.body.eventName == null || req.body.eventName === "") {
                    verify.flag = true;
                    verify.eventName = "回调时间不能为空";
                } else {
                    input.eventName = req.body.eventName;
                }
            }
            if (options.from) {
                if (!isValidAddress(req.body.caller)) {
                    verify.flag = true;
                    verify.caller = "无效的调用者";
                } else {
                    input.caller = req.body.caller.indexOf('0x') >= 0 ? req.body.caller : '0x' + req.body.caller;
                    input.balance = web3.eth.getBalance(input.caller);
                }
            }
            if (options.address) {
                if (!isValidAddress(req.body.address)) {
                    verify.flag = true;
                    verify.address = "无效的调用者";
                }
                else {
                    input.caller = req.body.address.indexOf('0x') >= 0 ? req.body.address : '0x' + req.body.address;
                    input.balance = web3.eth.getBalance(input.caller);
                }
            }
            var arr = [];
            var params = req.body.params;
            if (params != null) {
                for (var key in params) {
                    if (params.hasOwnProperty(key)) {
                        arr.push(params[key]);
                    }
                }
            }
            input.params = arr;
            input.rawParams = params;
            if (verify.flag) {
                reject(verify);
            } else {
                resolve(input);
            }
        }
        catch (e) {
            reject(e);
        }
    });
}

function createContractRawTransaction(params) {
    return new Promise(function (resolve, reject) {
        try {
            var pk = params.privateKey;
            var caller = params.caller;
            var abi = params.abi;
            var data = params.data;
            var arr = params.params;
            if (arr.length > 0) {
                var contract = web3.eth.contract(abi);
                var initParams = contract.getData.apply(contract, arr).replace('undefined', '');
                data = data + initParams;
            }
            var privateKey = new Buffer(pk, 'hex');
            var nonce = web3.eth.getTransactionCount(caller);
            var gasPriceHex = web3.toHex(10000);
            var tx = new Tx({
                nonce: web3.toHex(nonce),
                gasPrice: gasPriceHex,
                gasLimit: "0xffffffff",
                from: caller,
                value: '0x0',
                data: '0x' + data
            });
            tx.sign(privateKey);
            var stx = '0x' + tx.serialize().toString('hex');
            resolve({input: params, stx: stx});
        }
        catch (e) {
            reject(e);
        }
    });
}

function sendRawTransaction(tx) {
    return new Promise(function (resolve, reject) {
        try {
            web3.eth.sendRawTransaction(tx.stx, function (e, h) {
                if (e) {
                    reject(e);
                } else {
                    tx.hash = h;
                    resolve(tx);
                }
            })
        } catch (e) {
            reject(e);
        }
    })
}

function sleep(seconds) {
    var e = new Date().getTime() + (seconds * 1000);
    while (new Date().getTime() <= e) {
    }
}

function waitForTransactionReceipt(tx) {
    return new Promise(function (resolve, reject) {
        try {
            console.log('waiting for contract to be mined');
            var receipt = web3.eth.getTransactionReceipt(tx.hash);
            // If no receipt, try again in 1s
            var counter = 0;
            while (receipt == null) {
                if (counter > 30) {
                    break;
                }
                sleep(2);
                counter++;
                receipt = web3.eth.getTransactionReceipt(tx.hash);
            }
            if (counter > 30) {
                reject("Contract Deploy timeout!");
            }
            // The transaction was mined, we can retrieve the contract address
            console.log('contract address: ' + receipt);
            tx.receipt = receipt;
            resolve(tx);
        }
        catch (e) {
            reject(e);
        }
    });
}

app.post('/deployContract', function (req, res) {
    prepareParameters(req, {
        privateKey: true,
        from: false,
        address: true,
        contract: false,
        abi: true,
        data: true,
        method: false,
        eventName: false
    }).then(createContractRawTransaction)
        .then(sendRawTransaction)
        .then(waitForTransactionReceipt)
        .then(returnEther)
        .then(function (tx) {
                res.send(tx.receipt);
            },
            function (e) {
                res.send({
                        hasError: true,
                        error: e.message,
                        data: null
                    }
                );
            });
});

function createRawTransaction(params) {
    return new Promise(function (resolve, reject) {
        try {
            var pk = params.privateKey;
            var caller = params.caller;
            var contractAddress = params.contract;
            var method = params.method;
            var abi = params.abi;
            var arr = params.params;
            var privateKey = new Buffer(pk, 'hex');
            var nonce = web3.eth.getTransactionCount(caller);
            var c = web3.eth.contract(abi).at(contractAddress);
            var methodFunc = c[method];
            var data = methodFunc.getData.apply(methodFunc, arr);
            var tx = new Tx({
                nonce: web3.toHex(nonce),
                gasPrice: web3.toHex(10000),
                gasLimit: web3.toHex(1000000),
                from: caller,
                to: contractAddress,
                value: '0x0',
                data: data
            });
            tx.sign(privateKey);
            var stx = '0x' + tx.serialize().toString('hex');
            resolve({input: params, stx: stx, instance: c});
        }
        catch (e) {
            reject(e);
        }
    });
}

function watchTransactionEvent(tx) {
    return new Promise(function (resolve, reject) {
        try {
            var c = tx.instance;
            var event = c[tx.input.eventName]({from: tx.input.caller});
            event.watch(function (e, r) {
                event.stopWatching();
                if (e) {
                    reject(e);
                }
                else {
                    tx.log = r.args;
                    resolve(tx);
                }
            });
        } catch (e) {
            reject(e);
        }
    })
}

function returnEther(tx) {
    return new Promise(function (resolve, reject) {
        try {
            var caller = tx.input.caller;
            var balance = web3.eth.getBalance(caller);
            var miner = web3.eth.accounts[0];
            if (caller !== miner) {
                web3.eth.sendTransaction({
                    from: miner,
                    to: caller,
                    value: tx.input.balance - balance,
                    gasLimit: 21000,
                    gasPrice: 10000
                }, function (e, r) {
                    if (e) {
                        reject(e);
                    } else {
                        resolve(tx);
                    }
                });
            } else {
                resolve(tx);
            }
        }
        catch (e) {
            reject(e);
        }
    });
}

app.post('/transaction', function (req, res) {
    prepareParameters(req, {
        privateKey: true,
        from: true,
        address: false,
        contract: true,
        abi: true,
        data: false,
        method: true,
        eventName: true
    }).then(createRawTransaction)
        .then(sendRawTransaction)
        .then(watchTransactionEvent)
        .then(returnEther)
        .then(function (tx) {
                res.send({hasError: false, error: null, data: tx.log});
            },
            function (e) {
                res.send({
                        hasError: true,
                        error: e.message,
                        data: null
                    }
                );
            });
});

function callContract(params) {
    return new Promise(function (resolve, reject) {
        try {
            var abi = params.abi;
            var contractAddress = params.contract;
            var contractInstance = web3.eth.contract(abi).at(contractAddress);
            var arr = params.params;
            var method = params.method;
            var result = arr.length > 0 ? contractInstance[method]["call"].apply(this, arr) : contractInstance[method].call();
            resolve(result);
        }
        catch (e) {
            reject(e);
        }
    });
}

app.post('/call', function (req, res) {
    prepareParameters(req, {
        privateKey: false,
        from: false,
        address: false,
        contract: true,
        abi: true,
        data: false,
        method: true,
        eventName: false
    }).then(callContract)
        .then(function (r) {
                res.send({hasError: false, error: null, data: r});
            },
            function (e) {
                res.send({
                        hasError: true,
                        error: e.message,
                        data: null
                    }
                );
            });
});

function queryLogs(params) {
    return new Promise(function (resolve, reject) {
        try {
            var abi = params.abi;
            var contractAddress = params.contract;
            var contractInstance = web3.eth.contract(abi).at(contractAddress);
            var event = contractInstance[params.eventName](params.rawParams, {fromBlock: 0, toBlock: 'latest'});
            event.get(function (e, log) {
                if (e) {
                    reject(e);
                }
                else {
                    resolve(log);
                }
            });
        } catch (e) {
            reject(e);
        }
    });
}

app.post('/query', function (req, res) {
    prepareParameters(req, {
        privateKey: false,
        from: false,
        address: false,
        contract: true,
        abi: true,
        data: false,
        method: false,
        eventName: true
    }).then(queryLogs)
        .then(function (r) {
                res.send({
                    hasError: false,
                    error: null,
                    data: r
                });
            },
            function (e) {
                res.send({
                        hasError: true,
                        error: e.message,
                        data: null
                    }
                );
            });
});

function readFileAsync(filename) {
    return new Promise(function (resolve, reject) {
        fs.readFile(filename, function (err, data) {
            if (err)
                reject(err);
            else
                resolve(data);
        });
    });
};

function readDirAsync(dir) {
    return new Promise(function (resolve, reject) {
        fs.readdir(dir, function (err, files) {
            if (err)
                reject(err);
            else
                resolve(files);
        });
    });
};

function readKeystore(account) {
    var keystore = '/home/ethereum/data/keystore';
    return new Promise(function (resolve, reject) {
        readDirAsync(keystore).then(function (files) {
            var flag = false;
            for (var i = 0; i < files.length; i++) {
                var file = files[i];
                console.log(file);
                if (file.endsWith(account.address.slice(2))) {
                    flag = true;
                    readFileAsync(keystore + "/" + file).then(function (data) {
                        var json = JSON.parse(data);
                        var key = keythereum.recover(account.password, json).toString('hex');
                        console.log(data);
                        resolve({
                            account: account.address,
                            key: key,
                            file: json
                        });
                    });
                }
            }
            if (!flag) {
                reject(new Error("未找到公钥文件"));
            }
        });
    });
}

function initializeEther(account) {
    return new Promise(function (resolve, reject) {
        if (web3.eth.accounts.length > 0) {
            web3.eth.sendTransaction({
                from: web3.eth.accounts[0],
                to: account.address,
                value: web3.toWei(0.01, 'ether'),
                gasLimit: 21000,
                gasPrice: 1000
            }, function (e, d) {
                if (e) {
                    reject(e);
                } else {
                    resolve(account);
                }
            });
        }
    });
}

function createAccount(password) {
    return new Promise(function (resolve, reject) {
        web3.personal.newAccount(password, function (e, r) {
            if (e) {
                reject(e);
            } else {
                console.log(r);
                resolve(r);
            }
        });
    })
}

app.get('/newAccount', function (req, res) {
    var password = req.query.password;
    createAccount(password).then(function (r) {
        return {address: r, password: password};
    }).then(initializeEther).then(readKeystore).then(function (d) {
            res.send({
                hasError: false,
                error: null,
                data: d
            });
        },
        function (e) {
            res.send({
                    hasError: true,
                    error: e.message,
                    data: null
                }
            );
        });

});
app.get('/balance', function (req, res) {
    try {
        var account = req.query.account;
        var balance = web3.eth.getBalance(account);
        res.send({hasError: false, error: null, data: web3.fromWei(balance, 'ether')});
    }
    catch (e) {
        res.send({hasError: true, error: e.message, data: null})
    }
});
app.get('/transfer', function (req, res) {
    try {
        var account = req.query.account;
        var value = req.query.value;
        web3.eth.sendTransaction({
            from: web3.eth.accounts[0],
            to: account,
            value: web3.toWei(value, 'ether'),
            gasLimit: 21000,
            gasPrice: 1000
        });
        res.send({hasError: false, error: null, data: true});
    }
    catch (e) {
        res.send({hasError: true, error: e.message, data: null})
    }
});
app.get('/transferBack', function (req, res) {
    try {
        var accounts = web3.eth.accounts;
        for (var i = 1; i < accounts.length; i++) {
            var account = accounts[0];
            try {
                web3.personal.unlockAccount(account, "123456", 0);
                web3.eth.sendTransaction({
                    from: account,
                    to: web3.eth.accounts[0],
                    value: web3.eth.getBalance(account),
                    gasLimit: 21000,
                    gasPrice: 1000
                });
            } catch (ex) {
            }
        }
        res.send({hasError: false, error: null, data: true});
    }
    catch (e) {
        res.send({hasError: true, error: e.message, data: null})
    }
});
app.get('/unlock', function (req, res) {
    var account = req.query.account;
    var password = req.query.password;
    res.send(web3.personal.unlockAccount("0x" + acc, password, 0));
});
app.get('/accounts', function (req, res) {
    res.send(web3.eth.accounts);
});
app.get('/block', function (req, res) {
    res.send(web3.eth.getBlock(web3.eth.blockNumber));
});
app.get('/startminer', function (req, res) {
    web3.miner.start();
    res.send(true);
});
app.get('/stopminer', function (req, res) {
    web3.miner.stop();
    res.send(true);
});
app.get('/getCoinbase', function (req, res) {
    res.send(web3.eth.coinbase);
});
/*app.get('/getPrivateKeyOf', function (req, res) {
    var account = req.query.account;
    var password = req.query.password;
    readKeystore({address: account, password: password}).then(function (d) {
            res.send({
                hasError: false,
                error: null,
                data: d
            });
        },
        function (e) {
            res.send({
                    hasError: true,
                    error: e.message,
                    data: null
                }
            );
        });
});*/
app.get('/node', function (req, res) {
    res.send(web3.admin.nodeInfo);
});
app.get('/ipfs', function (req, res) {
    ipfs.files.get('QmUtbpi2g5zXb7a8tHAnntwimu67Fj9SWLe9TbauCvbnRS', function (err, files) {
        files.forEach(function (file) {
            res.header("Content-Type", "application/octet-stream;charset=utf-8");
            res.header("Content-Disposition", "attachment; filename=" + file.path);
            res.write(file.content);
            res.end();
        });
    });
});
//动态添加节点，需要出入节点地址，IP和端口
app.get('/addPeer', function (req, res) {
    var node = req.query.node;
    var ip = req.query.ip;
    var port = req.query.port;
    web3.admin.addPeer("enode://" + node + "@" + ip + ":" + port);
    res.send(true);
});
app.get('/isConnected', function (req, res) {
    try {
        var connected = web3.isConnected();
        res.send(connected);
    }
    catch (e) {
        res.send(false);
    }
});
//error handling
app.use(function (err, req, res, next) {
    res.send({
        hasError: true,
        message: err,
        data: null
    });
});
var server = app.listen(9090, function () {
    var host = server.address().address;
    var port = server.address().port;
    if (web3.eth.accounts.length > 0)
        web3.personal.unlockAccount(web3.eth.accounts[0], "123456", 0);
    console.log('Example app listerning at http://%s:%s', host, port);
});