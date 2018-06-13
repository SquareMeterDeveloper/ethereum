apt-get install git
apt-get install golang
apt-get install dirmngr
apt-get install software-properties-common
add-apt-repository -y ppa:ethereum/ethereum
debian下安装需先修改 /etc/opt/sources.list.d/目录下文件内容对应ubuntu的版本号，然后执行
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2A518C819BE37D2C2031944D1C52189C923F6CA9
apt-get update
apt-get install ethereum
mkdir /home/ethereum
cd /home/ethereum
mkdir data
mkdir temp
上传文件到temp目录包括：genesis.json,static-nodes.json,start_chain.sh,start_nodejs.sh,start_miner.sh
geth --datadir "/home/ethereum/data" init "/home/ethereum/temp/genesis.json"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
nvm install 8.11.1
nvm alias default 8.11.1
mkdir node
cd node
npm init
npm install express@4.16.3
npm install bluebird@3.5.1
npm install web3@0.20.1
npm install web3admin@0.4.4
npm install keythereum@1.0.4
npm install ethereumjs-tx@1.3.4
npm install ipfs-api@22.0.1
npm install -g eth-mine-when-need@1.1.6