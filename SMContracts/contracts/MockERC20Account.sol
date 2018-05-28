pragma solidity ^0.4.0;

import "../contracts/ContractReceiver.sol";
import "../contracts/ERC20.sol";

contract MockERC20Account is ContractReceiver {
    ERC20 token;

    function MockERC20Account(ERC20 _token) public {
        token = _token;
    }

    function transfer(address to, uint value) external {
        token.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) external {
        token.transferFrom(from, to, value);
    }

    function approve(address to, uint value) external {
        token.approve(to, value);
    }

    function tokenFallback(address sender, uint value, address _token) public returns (uint){
        if (sender != address(0) && _token != address(0))
            return value;
        return 0;
    }
}
