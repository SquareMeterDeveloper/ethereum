pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import '../contracts/SafeMath.sol';
import '../contracts/Owned.sol';
import '../contracts/ContractReceiver.sol';

//@title ERC20Token
contract ERC20Token is ERC20, SafeMath {
    struct Accounts {
        address[] keys;
        mapping(address => AccountBalance) balances;
    }

    struct AccountBalance {
        bool flag;
        uint keyIndex;
        uint balance;
    }

    string  tokenSymbol;
    uint tokenDecimals;
    uint supply;
    Accounts accounts;
    mapping(address => mapping(address => uint)) allowanceMap;

    //@dev 符号
    function symbol() public constant returns (string _symbol) {
        return tokenSymbol;
    }

    //@dev 份额拆分倍数
    function decimals() public constant returns (uint _decimals) {
        return tokenDecimals;
    }

    //@dev 总余额
    function totalSupply() public constant returns (uint _totalSupply){
        return supply;
    }

    function holdersCount() public returns (uint count){
        return accounts.keys.length;
    }

    function holders() public returns (address[] _holders){
        return accounts.keys;
    }

    function holderAt(uint index) public returns (address adr, uint balance){
        address a = accounts.keys[index];
        return (a, accounts.balances[a].balance);
    }

    function ERC20Token(string _symbol, uint _decimals, uint _total) public {
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        supply = _total;
    }

    //@dev 转账给指定地址的账户，余额不足或对方账户超限将执行失败，如果转入账户是合约地址，合约必须是ContractReceiver
    //@param to 转入的账户地址
    //@param value 转出数量
    function transfer(address to, uint value, string data) public returns (bool success) {
        if (balanceOf(msg.sender) < value) {
            Transfer(msg.sender, to, data, 0, 1);
            return false;
        }
        if (msg.sender == to) {
            Transfer(msg.sender, to, data, value, 0);
            return true;
        }
        address from = msg.sender;
        return transferTo(from, to, value, data);
    }

    function transfer(address to, uint value) public returns (bool success) {
        return transfer(to, value, "");
    }

    function transferFrom(address from, address to, uint value) public returns (bool){
        return transferFrom(from, to, value, "");
    }

    function transferTo(address from, address to, uint value, string data) private returns (bool){
        uint balanceFrom = balanceOf(from) - value;
        uint balanceTo;
        bool flagTo;
        (balanceTo, flagTo) = safeAdd(balanceOf(to), value);
        if (flagTo) {
            //如果是向本合约转账需要转入方为Owner
            //向非本合约转账需要合约实现ContractReceiver接口
            if (to == address(this)) {
                updateBalance(to, balanceTo);
                updateBalance(from, balanceFrom);
                supply -= value;
                Transfer(from, to, data, value, 0);
            }
            else if (isContract(to)) {
                ContractReceiver receiver = ContractReceiver(to);
                uint v = receiver.tokenFallback(from, value, this);
                if (v > 0) {
                    updateBalance(to, balanceOf(to) + v);
                    updateBalance(from, balanceOf(from) - v);
                    Transfer(from, to, data, v, 0);
                } else {
                    Transfer(from, to, data, 0, 2);
                }
            }
            else {
                updateBalance(to, balanceTo);
                updateBalance(from, balanceFrom);
                Transfer(from, to, data, value, 0);
            }
            return true;
        }
        else {
            Transfer(from, to, data, 0, 3);
            return false;
        }
    }

    function updateBalance(address adr, uint balance) internal {
        accounts.balances[adr].balance = balance;
        if (balance > 0) {
            if (!accounts.balances[adr].flag) {
                accounts.balances[adr].keyIndex = accounts.keys.length;
                accounts.keys.push(adr);
                accounts.balances[adr].flag = true;
            }
        }
        else {
            if (accounts.balances[adr].flag) {
                accounts.balances[adr].flag = false;
                uint keyIndex = accounts.balances[adr].keyIndex;
                if (keyIndex != accounts.keys.length - 1) {
                    address v = accounts.keys[accounts.keys.length - 1];
                    accounts.keys[keyIndex] = v;
                    accounts.balances[v].keyIndex = keyIndex;
                }
                accounts.balances[adr].keyIndex = 0;
                accounts.keys.length -= 1;
            }
        }
    }

    function transferFrom(address from, address to, uint value, string data) public returns (bool){
        if (balanceOf(from) < value) {
            Transfer(from, to, data, 0, 1);
            return false;
        }
        if (allowanceMap[from][msg.sender] < value) {
            Transfer(from, to, data, 0, 1);
            return false;
        }
        bool success = transferTo(from, to, value, data);
        if (success) {
            allowanceMap[from][msg.sender] -= value;
        }
        return success;
    }

    function approve(address to, uint value) external returns (bool){
        allowanceMap[msg.sender][to] = value;
        Approve(msg.sender, to, value, 0);
        return true;
    }

    //@dev 是否是合约地址
    //@param adr 地址
    function isContract(address adr) private view returns (bool) {
        uint length;
        assembly {
            length := extcodesize(adr)
        }
        return (length > 0);
    }


    //@dev 获取某账户余额
    //@param owner账户地址
    function balanceOf(address owner) public constant returns (uint balance) {
        return accounts.balances[owner].balance;
    }

    //@dev 获取某账户授权余额
    //@param owner
    //@param spender
    function allowance(address owner, address spender) public constant returns (uint _remaining) {
        return allowanceMap[owner][spender];
    }
}

