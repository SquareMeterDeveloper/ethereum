pragma solidity ^0.4.0;

import '../contracts/ERC721Project.sol';

contract MockERC721Project is ERC721Project {

    uint id = 10000;
    bool liquidated;

    function tokenId() external view returns (uint){
        return id;
    }

    function setTokenId(uint tokenId) external {
        id = tokenId;
    }

    function commissionChanging(address from, address to, address sender) external returns (bool) {
        return true;
    }

    function commissionChanged(address from, address to, address sender) external returns (bool) {
        return true;
    }

    function liquidate() external returns (bool){
        liquidated = true;
        return true;
    }

    function isLiquidated() external returns (bool){
        return liquidated;
    }

    function createToken() onlyOperator external returns (address) {}

    function createDealer() onlyOperator external returns (address) {}

    function token() external returns (address){}

    function dealer() external returns (address){}

}