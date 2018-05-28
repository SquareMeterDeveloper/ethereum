pragma solidity ^0.4.0;

// ----------------------------------------------------------------------------
// 合约拥有者
// ----------------------------------------------------------------------------
contract Owned {
    address owner;
    address operator;

    event ChangeOperator(address indexed from, address indexed to);
    event TransferOwnership(address indexed from, address indexed to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //操作员
    modifier onlyOperator {
        require(msg.sender == operator);
        _;
    }
    //操作员
    modifier operatorOrOwner {
        require(msg.sender == operator || msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
        operator = msg.sender;
    }

    //转移权限
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        TransferOwnership(msg.sender, owner);
    }

    //改变操作员
    function changeOperator(address _newOperator) public onlyOwner {
        operator = _newOperator;
        ChangeOperator(msg.sender, operator);
    }

    function getOwner() public view returns (address){
        return owner;
    }

    function getOperator() public view returns (address){
        return operator;
    }
}
