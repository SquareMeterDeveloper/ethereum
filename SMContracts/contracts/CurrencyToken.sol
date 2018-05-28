pragma solidity ^0.4.0;

import '../contracts/ERC20Token.sol';

contract CurrencyToken is ERC20Token {

    event Mint(address indexed from, address indexed to, uint value, uint code);

    function CurrencyToken(string symbol, uint decimals, uint totalSupply)
    ERC20Token(symbol, decimals, totalSupply) public {

    }

    //@dev 发行货币给Owner
    //@param value 数量
    function mint(uint value) onlyOwner() external {
        uint balance;
        bool flag;
        address to = owner;
        (balance, flag) = safeAdd(balanceOf(to), value);
        if (flag) {
            updateBalance(to, balance);
            supply += value;
            Mint(msg.sender, to, value, 0);
        }
        else {
            Mint(msg.sender, to, 0, 1);
        }
    }
}
