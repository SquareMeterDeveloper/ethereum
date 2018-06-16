pragma solidity ^0.4.0;

import '../contracts/Owned.sol';

contract NamingController is Owned {
    event SetContract(address indexed sender, string name, uint indexed key, address adr, uint code);

    function getContract(string name, uint key) external returns (address);

    function getContracts(string name) external returns (address[]);

    function setContract(string name, uint key, Owned adr) external;
}
