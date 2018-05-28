pragma solidity ^0.4.0;

contract ContractReceiver {
    function tokenFallback(address sender, uint value, address token) public returns (uint);
}
