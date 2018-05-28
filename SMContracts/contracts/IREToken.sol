pragma solidity ^0.4.0;

import '../contracts/ERC20Token.sol';

contract IREToken is ERC20Token {
    function IREToken(string symbol, uint decimals, uint total)
    ERC20Token(symbol, decimals, total)
    public {
        initialize();
    }

    function initialize() private {
        if (supply > 0) {
            accounts.keys.push(owner);
            accounts.balances[owner].flag = true;
            accounts.balances[owner].balance = supply;
        }
    }
}
