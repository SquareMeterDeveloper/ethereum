pragma solidity ^0.4.0;

import '../contracts/Owned.sol';
//@title ERC20
contract ERC20 is Owned {
    //委托量
    function allowance(address tokenOwner, address spender) public constant returns (uint _remaining);
    //账户的余额
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    //账户余额
    function holderAt(uint index) public returns (address adr, uint balance);
    //总人数
    function holdersCount() public returns (uint count);
    //拥有份额的账户
    function holders() public returns (address[] _holders);
    //名称
    function symbol() public constant returns (string _symbol);
    //份额小数位数
    function decimals() public constant returns (uint _decimals);
    //总份额数
    function totalSupply() public constant returns (uint _totalSupply);
    //转账
    function transfer(address to, uint value, uint data) public returns (bool success);
    //转账
    function transferFrom(address from, address to, uint value, uint data) public returns (bool success);
    //转账
    function transfer(address to, uint value) public returns (bool success);
    //转账
    function transferFrom(address from, address to, uint value) public returns (bool success);
    //转账
    function approve(address to, uint value) external returns (bool ok);
    //转账事件
    event Transfer(address indexed from, address indexed to, uint indexed data, uint value, uint code);
    //转账事件
    event Approve(address indexed from, address indexed to, uint value, uint code);
}
