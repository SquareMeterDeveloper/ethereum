pragma solidity ^0.4.0;

import '../contracts/Owned.sol';
import '../contracts/NamingController.sol';

contract NamingRepository is NamingController {
    struct Namings {
        uint[] keys;
        mapping(uint => Naming) map;
    }

    struct Naming {
        bool flag;
        uint key;
        address adr;
    }

    mapping(string => Namings) namings;

    function getContract(string name, uint key) external returns (address){
        return namings[name].map[key].adr;
    }

    function getContracts(string name) external returns (address[]){
        uint len = namings[name].keys.length;
        address[] memory contracts = new address[](len);
        for (uint i = 0; i < namings[name].keys.length; i++) {
            contracts[i] = namings[name].map[namings[name].keys[i]].adr;
        }
        return contracts;
    }

    function setContract(string name, uint key, Owned adr) onlyOperator external {
        if (!namings[name].map[key].flag) {
            namings[name].keys.push(key);
            namings[name].map[key].flag = true;
        }
        namings[name].map[key].adr = adr;
        SetContract(msg.sender, name, key, adr, 0);
    }
}
