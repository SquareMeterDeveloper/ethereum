pragma solidity ^0.4.0;

import '../contracts/Owned.sol';
import "../contracts/NamingController.sol";

contract ERC721ProfitDistributor is Owned {
    event Pay(address indexed from, string indexed taskId, uint total, uint residual, uint code);

    function pay(string taskId) onlyOperator external;
}
