pragma solidity ^0.4.0;
import '../contracts/Owned.sol';
contract VAM is Owned {
    event Start(address from, uint code);
    event Execute(address from, uint code);

    //@dev 启动合约
    function start() onlyOperator external;

    //@dev执行合约
    function execute(uint valueA, uint valueB) onlyOperator external;
}
