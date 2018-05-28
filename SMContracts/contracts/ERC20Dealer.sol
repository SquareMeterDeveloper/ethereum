pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import '../contracts/Owned.sol';

contract ERC20Dealer is Owned {

    //发售流程：启动-关闭-分配份额-终止
    event Start(address indexed from, uint code);
    event Close(address indexed from,  uint code);
    event Purchase(address indexed from,  uint code);
    event Finalize(address indexed from,  uint code);

    //@dev 启动发售
    function start() onlyOperator() public;

    //@dev 关闭发售
    function close() onlyOperator() public;

    //@dev 终止流程
    function finalize() onlyOperator() public;

    //@dev 是否已关闭
    function isClosed() public returns(bool);

    //@dev是否发售失败
    function isFailed() public returns(bool);
}
