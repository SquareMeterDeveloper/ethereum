pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";
import "../contracts/LotteryTester.sol";
import "../contracts/LotteryNumberTester.sol";
import "../contracts/IREToken.sol";
import "../contracts/CurrencyToken.sol";

//@title 测试抽签程序终止功能，抽签终止需退还资产和申购款
contract LotteryTestFinalize is ContractReceiver {
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    IREToken asset = new IREToken("Test", 2, 10000);
    Lottery lottery = new Lottery(10000, 2, 1, 10000, asset, cny);

    event TestEvent(bool indexed result, string message);

    function test1() public {
        Assert.equal(asset.balanceOf(this), 10000, "资产份额应为10000");
        asset.transfer(lottery, 10000);
        Assert.equal(lottery.getTotalShares(), 10000, "资产份额应为10000");
        Assert.equal(asset.balanceOf(lottery), 10000, "资产份额应为10000");

        lottery.start();
        cny.mint(10000);
        cny.transfer(lottery, 2000);
        Assert.equal(cny.balanceOf(this), 8000, "余额应为8000");

        lottery.finalize();
        Assert.equal(cny.balanceOf(this), 10000, "余额应为10000");
        Assert.equal(asset.balanceOf(lottery), 0, "资产份额应为0");
        Assert.equal(asset.balanceOf(this), 10000, "资产份额应为10000");
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}
