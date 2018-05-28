pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CurrencyToken.sol";
import "../contracts/MockERC20Account.sol";

contract CNYTokenTest {
    CurrencyToken token = new CurrencyToken("CNYT", 6, 0);
    MockERC20Account ac = new MockERC20Account(token);

    function test1() public {
        Assert.equal(token.totalSupply(), 0, "总余额不正确");
        Assert.equal(token.decimals(), 6, "Decimals不正确");
        Assert.equal(token.balanceOf(this), 0, "初始化份额不正确");
        Assert.equal(token.holdersCount(), 0, "份额持有人个数不是0");

        token.mint(100000);
        Assert.equal(token.totalSupply(), 100000, "总余额不正确");
        Assert.equal(token.balanceOf(this), 100000, "发行失败");
        Assert.equal(token.holdersCount(), 1, "份额持有人个数不是1");

        token.transfer(address(8888), 20000);
        Assert.equal(token.balanceOf(this), 80000, "剩余份额不是80000");
        Assert.equal(token.balanceOf(address(8888)), 20000, "收到份额不是20000");
        Assert.equal(token.holdersCount(), 2, "份额持有人个数不是2");

        token.transfer(token, 20000);
        Assert.equal(token.balanceOf(this), 60000, "剩余份额不是60000");
        Assert.equal(token.totalSupply(), 80000, "总余额不正确");

        token.transfer(address(8888), 60000);
        Assert.equal(token.balanceOf(this), 0, "剩余份额不是80000");
        Assert.equal(token.balanceOf(address(8888)), 80000, "收到份额不是80000");
        Assert.equal(token.holdersCount(), 2, "份额持有人个数不是1");

        token.mint(100000);
        Assert.equal(token.balanceOf(this), 100000, "发行失败");
        Assert.equal(token.holdersCount(), 3, "份额持有人个数不是2");
        Assert.equal(token.totalSupply(), 180000, "总余额不正确");

        token.approve(ac, 10000);
        Assert.equal(token.allowance(this, ac), 10000, "授权额度不正确");
        ac.transferFrom(this, address(999), 5000);
        Assert.equal(token.allowance(this, ac), 5000, "授权额度不正确");
        Assert.equal(token.balanceOf(address(999)), 5000, "余额不正确");
    }
}
