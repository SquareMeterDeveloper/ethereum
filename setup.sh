//安装以太坊需要的包
apt-get install git
apt-get install golang
apt-get install dirmngr
apt-get install software-properties-common

//安装geth
add-apt-repository -y ppa:ethereum/ethereum
debian下安装需先修改 /etc/apt/sources.list.d/目录下文件内容对应ubuntu的版本号，如bionic，然后执行
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2A518C819BE37D2C2031944D1C52189C923F6CA9
apt-get update
apt-get install ethereum

//创建以太坊应用相关目录
mkdir /home/ethereum
cd /home/ethereum
mkdir data
mkdir temp

//上传文件到temp目录包括：
//    1.genesis.json 区块链创世文件，所有平方米私有链都一样
//    2.static-nodes.json(不同环境对应不同的文件，注意不要弄错)
//    3.start_chain.sh(不同环境networkid不同，dev-45371，test-90778, prod-78336)
//    4.start_nodejs.sh
//    5.start_miner.sh
//    6.app.js

geth --datadir "/home/ethereum/data" init "/home/ethereum/temp/genesis.json"
cp /home/ethereum/temp/static-nodes.json /home/ethereum/data

//以下是安装Node相关组件
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
nvm install 8.11.1
nvm alias default 8.11.1
mkdir node
cp /home/ethereum/temp/app.js /home/ethereum/node
cd node

npm init
npm install express@4.16.3
npm install bluebird@3.5.1
npm install web3@0.20.1
npm install web3admin@0.4.4
npm install keythereum@1.0.4
npm install ethereumjs-tx@1.3.4
npm install ipfs-api@22.0.1

//安装全局包，以太坊按需挖矿监控进程，说明见：https://libraries.io/npm/eth-mine-when-need
npm install -g eth-mine-when-need@1.1.6

-----相关文件说明------

static-nodes.json dev节点列表
static-nodes_t.json test节点列表
static-nodes_p.json prod节点列表

*static-nodes.json文件需要放在对应以太坊目录，如/home/ethereum/data下。
*如果有新的节点加入，可考虑更新该文件

启动顺序：
1.start_chain.sh 启动以太坊客户端，不同环境networkid不同，dev-45371，test-90778, prod-78336，如需启动某IP跨域rpc访问需添加--rpccorsdomain="*"，*可以是某IP:Port。
2.start_nodejs.sh 启动node服务，启动node服务前需确保node环境参考setup。sh配置成功，app.js文件在/home/ethereum/node目录下。
3.start_miner.sh 启动按需挖矿监控，需安装eth-mine-when-need，参见setup.sh。

*以太坊geth进程重启，则需要重启node和按需挖矿