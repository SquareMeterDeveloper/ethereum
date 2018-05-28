pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import '../contracts/Owned.sol';

contract ERC721Project is Owned {

    function tokenId() external view returns (uint);

    function commissionChanging(address from, address to, address sender) external returns (bool);

    function commissionChanged(address from, address to, address sender) external returns (bool);

    function liquidate() external returns (bool);
}
