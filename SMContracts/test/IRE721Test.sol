pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IRE721.sol";

contract IRE721Test {
    IRE721 asset = new IRE721();

    function testCreate() public {
        asset.create(100000);

        Assert.equal(asset.totalSupply(), 1, "总量不正确");
        Assert.equal(asset.balanceOf(this), 1, "持有数量不正确");
        Assert.equal(asset.ownerOf(100000), this, "持有者不正确");

        asset.create(100000);

        Assert.equal(asset.totalSupply(), 1, "总量不正确");
        Assert.equal(asset.balanceOf(this), 1, "持有数量不正确");
        Assert.equal(asset.ownerOf(100000), this, "持有者不正确");

        asset.create(200000);

        Assert.equal(asset.totalSupply(), 2, "总量不正确");
        Assert.equal(asset.balanceOf(this), 2, "持有数量不正确");
        Assert.equal(asset.ownerOf(200000), this, "持有者不正确");
    }


    function testTransfer() public {
        asset.transfer(address(1), 10000);
        Assert.equal(asset.totalSupply(), 2, "总量不正确");
        Assert.equal(asset.balanceOf(this), 2, "持有数量不正确");
        Assert.equal(asset.balanceOf(address(1)), 0, "持有数量不正确");

        asset.transfer(address(1), 100000);
        Assert.equal(asset.totalSupply(), 2, "总量不正确");
        Assert.equal(asset.balanceOf(this), 1, "持有数量不正确");
        Assert.equal(asset.balanceOf(address(1)), 1, "持有数量不正确");
        Assert.equal(asset.ownerOf(100000), address(1), "持有者不正确");
    }
}
