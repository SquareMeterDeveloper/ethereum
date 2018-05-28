pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IREToken.sol";

contract IRETokenTest {
    event TestEvent(bool indexed result, string message);

    function test1() public {
        IREToken token = new IREToken("TEST", 2, 100000);
        Assert.equal(token.totalSupply(), 100000, "总份额不正确");
        Assert.equal(token.decimals(), 2, "Decimals不正确");
        Assert.equal(token.balanceOf(this), 100000, "初始化份额不正确");
        Assert.equal(token.holdersCount(), 1, "份额持有人个数不是1");

        token.transfer(address(8888), 20000);
        Assert.equal(token.balanceOf(this), 80000, "剩余份额不是80000");
        Assert.equal(token.balanceOf(address(8888)), 20000, "收到份额不是20000");
        Assert.equal(token.holdersCount(), 2, "份额持有人个数不是2");

        token.transfer(address(8888), 80000);
        Assert.equal(token.balanceOf(this), 0, "剩余份额不是0");
        Assert.equal(token.balanceOf(address(8888)), 100000, "收到份额不是100000");
        Assert.equal(token.holdersCount(), 1, "份额持有人个数不是1");
    }
}
