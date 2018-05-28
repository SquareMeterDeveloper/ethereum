'use strict';
var express = require('express');
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
app.post('/deployContract', function (req, res) {
    try {
        var pk = req.body.privateKey;
        var from = req.body.address;
        var abi = req.body.abi;
        var data = req.body.data;
        var params = req.body.params;
        var flag = false;
        var verify = {};
        var jsonAbi;
        if (pk == null || pk === "") {
            flag = true;
            verify.privateKey = "私钥无效";
        }
        if (abi == null || abi === "") {
            flag = true;
            verify.abi = "合约ABI不能为空";
        }
        else {
            jsonAbi = JSON.parse(abi);
            if (jsonAbi == null) {
                flag = true;
                verify.abi = "无效的ABI";
            }
        }
        if (!isValidAddress(from)) {
            flag = true;
            verify.caller = "无效的调用者";
        }
        if (data == null || data === "") {
            flag = true;
            verify.data = "合约代码不能为空";
        }
        if (flag) {
            res.send({hasError: true, error: verify, data: null})
        }
        if (params != null) {
            var arr = new Array();
            for (var key in params) {
                if (params.hasOwnProperty(key)) {
                    arr.push(params[key]);
                }
            }
            var contract = web3.eth.contract(jsonAbi);
            var initParams = contract.getData.apply(contract, arr).replace('undefined', '')
            data = data + initParams;
        }
        var caller = from.indexOf('0x') >= 0 ? from : '0x' + from;
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
        web3.eth.sendRawTransaction(stx, function (e, h) {
            if (e != null) {
                console.log(e);
                res.send({hasError: true, error: {message: e.message}, data: null});
            }
            else {
                waitForTransactionReceipt(h, res);
            }
        });

        function waitForTransactionReceipt(hash, res) {
            console.log('waiting for contract to be mined');
            const receipt = web3.eth.getTransactionReceipt(hash);
            // If no receipt, try again in 1s
            if (receipt == null) {
                setTimeout(function () {
                    waitForTransactionReceipt(hash, res);
                }, 1000);
            } else {
                // The transaction was mined, we can retrieve the contract address
                console.log('contract address: ' + receipt);
                res.send(receipt);
            }
        }
    }
    catch (e) {
        console.log(e);
        res.send({hasError: true, error: e.message, data: null})
    }
});

function isValidAddress(address) {
    return address != null && (address.indexOf('0x' >= 0 ? address.length === 42 : address.length === 40));
}

app.post('/transaction', function (req, res) {
    try {
        var pk = req.body.privateKey;
        var from = req.body.caller;
        var contract = req.body.contract;
        var abi = req.body.abi;
        var method = req.body.method;
        var eventName = req.body.eventName;
        var params = req.body.params;
        var gas = req.body.gas;
        var flag = false;
        var verify = {};
        var jsonAbi;
        if (pk == null || pk === "") {
            flag = true;
            verify.privateKey = "私钥无效";
        }
        if (abi == null || abi === "") {
            flag = true;
            verify.abi = "合约ABI不能为空";
        }
        else {
            jsonAbi = JSON.parse(abi);
            if (jsonAbi == null) {
                flag = true;
                verify.abi = "无效的ABI";
            }
        }
        if (!isValidAddress(from)) {
            flag = true;
            verify.caller = "无效的调用者";
        }
        if (!isValidAddress(contract)) {
            flag = true;
            verify.contract = "合约地址无效";
        }
        if (method == null || method === "") {
            flag = true;
            verify.method = "合约函数名不能为空";
        }
        if (eventName == null || eventName === "") {
            flag = true;
            verify.eventName = "回调时间不能为空";
        }
        if (flag) {
            res.send({hasError: true, error: verify, data: null})
        }
        var caller = from.indexOf('0x') >= 0 ? from : '0x' + from;
        var privateKey = new Buffer(pk, 'hex');
        var nonce = web3.eth.getTransactionCount(caller);
        var contractAddress = contract.indexOf('0x') >= 0 ? contract : '0x' + contract;
        var c = web3.eth.contract(jsonAbi).at(contractAddress);
        var methodFunc = c[method];
        var arr = new Array();
        if (params != null) {
            for (var key in params) {
                if (params.hasOwnProperty(key)) {
                    arr.push(params[key]);
                }
            }
        }
        var balanceBefore = web3.eth.getBalance(caller);
        var data = methodFunc.getData.apply(methodFunc, arr);
        var tx = new Tx({
            nonce: web3.toHex(nonce),
            gasPrice: web3.toHex(10000),
            gasLimit: web3.toHex(gas == null ? 1000000 : gas),
            from: caller,
            to: contractAddress,
            value: '0x0',
            data: data
        });
        tx.sign(privateKey);
        console.log(data);
        var stx = '0x' + tx.serialize().toString('hex');
        var event = c[eventName]({from: caller});
        event.watch(function (e, r) {
            event.stopWatching();
            if (e != null) {
                res.send({hasError: true, error: e.message, data: null});
            }
            else {
                var balanceAfter = web3.eth.getBalance(caller);
                var miner = web3.eth.accounts[0];
                if (caller !== miner) {
                    web3.eth.sendTransaction({
                        from: miner,
                        to: caller,
                        value: balanceBefore - balanceAfter,
                        gasLimit: 21000,
                        gasPrice: 10000
                    });
                }
                res.send({hasError: false, error: null, data: r.args});
            }
        });
        web3.eth.sendRawTransaction(stx, function (e, h) {
            if (e != null) {
                res.send({hasError: true, error: {message: e.message}, data: null});
            }
            else {

            }
        });
    } catch (e) {
        console.log(e);
        res.send({hasError: true, error: e.message, data: null})
    }
});
app.post('/call', function (req, res) {
    try {
        var abi = req.body.abi;
        var contract = req.body.contract;
        var method = req.body.method;
        var params = req.body.params;
        var flag = false;
        var verify = {};
        var jsonAbi;
        if (abi == null || abi === "") {
            flag = true;
            verify.abi = "合约ABI不能为空";
        }
        else {
            jsonAbi = JSON.parse(abi);
            if (jsonAbi == null) {
                flag = true;
                verify.abi = "无效的ABI";
            }
        }
        if (!isValidAddress(contract)) {
            flag = true;
            verify.contract = "合约地址无效";
        }
        if (method == null || method === "") {
            flag = true;
            verify.method = "合约函数名不能为空";
        }
        if (flag) {
            res.send({hasError: true, error: JSON.stringify(verify), data: null})
        }
        else {
            var contractAddress = contract.indexOf('0x') >= 0 ? contract : '0x' + contract;
            var contractInstance = web3.eth.contract(jsonAbi).at(contractAddress);
            var result;
            if (params == null || params === "") {
                result = contractInstance[method].call();
            }
            else {
                var arr = new Array();
                for (var key in params) {
                    if (params.hasOwnProperty(key)) {
                        arr.push(params[key]);
                    }
                }
                result = contractInstance[method]["call"].apply(this, arr);
            }
            res.send({hasError: false, error: null, data: result});
        }
    } catch (e) {
        res.send({hasError: true, error: e.message, data: null})
    }
});
app.post('/query', function (req, res) {
    try {
        var abi = req.body.abi;
        var contract = req.body.contract;
        var eventName = req.body.eventName;
        var params = req.body.params;
        var flag = false;
        var verify = {};
        var jsonAbi;
        if (abi == null || abi === "") {
            flag = true;
            verify.abi = "合约ABI不能为空";
        }
        else {
            jsonAbi = JSON.parse(abi);
            if (jsonAbi == null) {
                flag = true;
                verify.abi = "无效的ABI";
            }
        }
        if (!isValidAddress(contract)) {
            flag = true;
            verify.contract = "合约地址无效";
        }
        if (eventName == null || eventName === "") {
            flag = true;
            verify.method = "合约事件不能为空";
        }
        if (flag) {
            res.send({hasError: true, error: JSON.stringify(verify), data: null})
        }
        else {
            var contractAddress = contract.indexOf('0x') >= 0 ? contract : '0x' + contract;
            var contractInstance = web3.eth.contract(jsonAbi).at(contractAddress);
            var event = contractInstance[eventName](params, {fromBlock: 0, toBlock: 'latest'});
            event.get(function (e, log) {
                if (e != null) {
                    res.send({hasError: true, error: e.message, data: null});
                }
                else {
                    res.send({hasError: false, error: null, data: log});
                }
            });
        }
    } catch (e) {
        res.send({hasError: true, error: e.message, data: null})
    }
});
app.get('/newAccount', function (req, res) {
    try {
        var password = req.query.password;
        web3.personal.newAccount(password, function (e, r) {
            var keystore = '/home/ethereum/data/keystore';
            fs.readdir(keystore, function (err, files) {
                var flag = false;
                for (var i = 0; i < files.length; i++) {
                    var file = files[i];
                    if (file.endsWith(r.slice(2))) {
                        flag = true;
                        fs.readFile(keystore + "/" + file, function (err, data) {
                            var json = JSON.parse(data);
                            var key = keythereum.recover(password, json).toString('hex');
                            web3.eth.sendTransaction({
                                from: web3.eth.accounts[0],
                                to: r,
                                value: web3.toWei(0.01, 'ether'),
                                gasLimit: 21000,
                                gasPrice: 1000
                            });
                            res.send({hasError: false, error: null, data: {account: r, key: key, file: json}});
                        });
                    }
                }
                if (!flag)
                    res.send({hasError: true, error: "未找到公钥文件", data: null});
            });
        });
    } catch (e) {
        res.send({hasError: true, error: e.message, data: null})
    }
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
app.get('/getPrivateKeyOf', function (req, res) {
    var account = req.query.account;
    var password = req.query.password;
    var keystore = '/home/ethereum/data/keystore';
    fs.readdir(keystore, function (err, files) {
        var flag = false;
        for (var i = 0; i < files.length; i++) {
            var file = files[i];
            if (file.endsWith(account)) {
                flag = true;
                fs.readFile(keystore + "/" + file, function (err, data) {
                    var json = JSON.parse(data);
                    var key = keythereum.recover(password, json).toString('hex');
                    res.send(key);
                });
            }
        }
        if (!flag)
            res.send("No Account Found!");
    });
});
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
    res.send(true);
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
    web3.personal.unlockAccount(web3.eth.accounts[0], "123456", 0);
    console.log('Example app listerning at http://%s:%s', host, port);
});