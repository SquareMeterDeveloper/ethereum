pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Owned.sol";
import "../contracts/OwnedTester.sol";

contract OwnedTest {

    function test1() public {
        Owned owned = new Owned();
        OwnedTester tester = new OwnedTester(owned);
        owned.transferOwnership(tester);
        Assert.equal(owned.getOwner(), address(tester), "Owner错误");
        tester.transfer(this);
        Assert.equal(owned.getOwner(), this, "Owner错误");
        uint q = 1;
        Assert.equal(q, 1, "测试失败");
    }
}
