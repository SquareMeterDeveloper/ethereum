pragma solidity ^0.4.0;

import "../contracts/Owned.sol";

contract OwnedTester {
    Owned owned;

    function OwnedTester(Owned _owned) public{
        owned = _owned;
    }

    function transfer(address newOwner) public{
        owned.transferOwnership(newOwner);
    }
}
