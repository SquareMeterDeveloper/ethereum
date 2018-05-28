pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";
import "../contracts/LotteryTester.sol";
import "../contracts/IREToken.sol";
import "../contracts/CurrencyToken.sol";

contract LotteryTest_286654_654667 is ContractReceiver {
    event TestEvent(bool indexed result, string message);

    uint t = 286654;
    uint s = 654667;
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    LotteryTester tester = new LotteryTester();
    IREToken  asset = new IREToken("Test", 2, 1000000000);
    Lottery lottery = new Lottery(t, 0, 2, 1000000, asset, cny);

    function test1() public {
        asset.transfer(lottery, 28665400);
        uint amt = 2000000;
        cny.mint(amt);
        cny.transfer(tester, amt);
        Assert.equal(asset.balanceOf(lottery), 28665400, "份额应为28665400");
        Assert.equal(asset.balanceOf(tester), 0, "份额应为0");
        lottery.start();
        tester.purchase(cny, lottery, 100000, s, 2);
        lottery.close();
        lottery.draw();
    }

    function test2() public {
        tester.initialize(lottery);
        Assert.equal(lottery.getExponents(), 654321, "尾号结果不正确");
        Assert.equal(tester.validateNumbers(), true, "摇出号码有重号");
        Assert.equal(tester.validateTotal(t, s), true, "结果无法满足条件");
    }

    function test3() public {
        lottery.calculateShares();
        uint shares;
        uint cashLeft;
        (shares, cashLeft) = lottery.sharesOf(tester);
        Assert.equal(shares, 286654, "申购成功份额应为286654");
        Assert.equal(cashLeft, 736026, "剩余申购款应为736026");
        Assert.equal(cny.balanceOf(tester), 690666, "余额应为690666");
        Assert.equal(asset.balanceOf(tester), 0, "份额应为0");
    }

    function test4() public {
        lottery.allocateShares();
        Assert.equal(cny.balanceOf(tester), 1426692, "余额应为1426692");
        Assert.equal(asset.balanceOf(tester), 28665400, "份额应为28665400");
        //总申购款
        Assert.equal(cny.balanceOf(this), 573308, "出售总价不是573308");
    }


    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}
