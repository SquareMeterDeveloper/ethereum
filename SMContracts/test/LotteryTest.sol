pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";
import "../contracts/LotteryTester.sol";
import "../contracts/LotteryNumberTester.sol";
import "../contracts/IREToken.sol";
import "../contracts/CurrencyToken.sol";


contract LotteryTest {
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    IREToken asset = new IREToken("Test", 2, 100000000);
    Lottery lottery = new Lottery(100000, 2, 1, 10000, asset, cny);

    function testTotal1() public {
        Assert.equal(asset.balanceOf(this), 100000000, "Should be 10000000");
        asset.transfer(lottery, 100000);
        Assert.equal(lottery.getTotalShares(), 100000, "Should be 100000");
        Assert.equal(asset.balanceOf(lottery), 100000, "Should be 100000");
    }

    function testTotal2() public {
        LotteryNumberTester tester = new LotteryNumberTester(cny);
        cny.mint(1000000);
        cny.transfer(tester, 5000);
        Assert.equal(cny.balanceOf(tester), 5000, "Should be 5000");
        Assert.equal(tester.hasTransfer(this), true, "转入资金失败");
    }

    /*function testTotal3() public {
        cny = new CNYToken();
        IREToken asset = new IREToken("Test", 2, 1000000, this);
        Assert.equal(asset.balanceOf(this), 100000000, "Should be 100000");
        Lottery lottery = new Lottery("", 1000, 2, 1, 1000000, 10000, asset, cny);
        asset.transfer(lottery, 100000);
        Assert.equal(asset.balanceOf(lottery), 100000, "Should be 100000");
        LotteryTester tester = new LotteryTester();
        cny.mint(tester, 1000000);
        lottery.start();
        tester.purchase(cny, lottery, 100000, 8);
        Assert.equal(lottery.getTotalPurchased(), 8, "Should be 8");
    }*/
}
