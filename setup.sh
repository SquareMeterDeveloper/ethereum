apt-get install git
apt-get install golang
apt-get install dirmngr
apt-get install software-properties-common
add-apt-repository -y ppa:ethereum/ethereum
apt-get update
apt-get install ethereum
mkdir /home/ethereum
cd /home/ethereum
mkdir data
mkdir temp
geth --datadir "/home/ethereum/data" init "/home/ethereum/temp/genesis.json"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
nvm install 8.11.1
nvm alias default 8.11.1
mkdir node
cd node
npm init
npm install express
npm install bluebird
npm install web3@0.20.1
npm install web3admin
npm install keythereum
npm install ethereumjs-tx
npm install ifs-api
npm install -g eth-mine-when-need