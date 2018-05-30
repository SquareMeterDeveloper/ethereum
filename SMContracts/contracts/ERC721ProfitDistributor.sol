pragma solidity ^0.4.0;

import '../contracts/Owned.sol';
import "../contracts/NamingController.sol";

contract ERC721ProfitDistributor is Owned {
    event Pay(address indexed from, uint indexed taskId, uint total, uint residual, uint code);

    function pay(uint taskId) onlyOperator external;
}
