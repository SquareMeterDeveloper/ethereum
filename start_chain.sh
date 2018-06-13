#! /bin/sh
geth --datadir '/home/ethereum/data' --networkid 45371  --rpc --rpcapi="eth,net,personal,admin,miner,debug" --gasprice "1000" --targetgaslimit 42949276960 > /home/ethereum/data/log.log &
