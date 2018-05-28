pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";
import "../contracts/LotteryTester.sol";
import "../contracts/LotteryNumberTester.sol";
import "../contracts/IREToken.sol";
import "../contracts/CurrencyToken.sol";

//@title 测试认购流程，包括认购上限和认购过程的资金账户，资产账户余额变化
contract LotteryTestPurchase is ContractReceiver {
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    IREToken asset = new IREToken("Test", 2, 100000000);
    Lottery lottery = new Lottery(100000, 2, 1, 1000, asset, cny);

    event TestEvent(bool indexed result, string message);

    function test1() public {
        Assert.equal(asset.balanceOf(this), 100000000, "总份额应为100000");
        asset.transfer(lottery, 100000);
        lottery.start();
        cny.mint(1000000);
        cny.transfer(lottery, 100000);
        Assert.equal(cny.balanceOf(lottery), 100000, "存入金额应为100000");
        //Assert.equal(lottery.getTotalLeft(), 200000, "总可认购份额应为200000");
        Assert.equal(lottery.getUserLeft(), 1000, "用户剩余可申购份额为1000");

        lottery.purchase(200000, 800);
        Assert.equal(lottery.getTotalPurchased(), 800, "总已认购额应为800");
        //Assert.equal(lottery.getTotalLeft(), 199200, "总可认购份额数应为199200");
        Assert.equal(lottery.getUserLeft(), 200, "用户认购份额余额应为200");
        Assert.equal(cny.balanceOf(lottery), 800, "存入金额应为800");
        Assert.equal(cny.balanceOf(this), 999200, "剩余金额应为999200");

        cny.transfer(lottery, 1000);
        Assert.equal(cny.balanceOf(lottery), 1800, "存入金额应为1800");

        lottery.purchase(273848, 800);
        Assert.equal(lottery.getTotalPurchased(), 1000, "总已认购额应为1000");
        //Assert.equal(lottery.getTotalLeft(), 199000, "总认购余额应为199000");
        Assert.equal(lottery.getUserLeft(), 0, "用户还可认购份额数应为0");
        Assert.equal(cny.balanceOf(lottery), 1000, "转入金额应为1000");
        Assert.equal(cny.balanceOf(this), 999000, "剩余金额应为999000");
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}