pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";
import "../contracts/LotteryTester.sol";
import "../contracts/IREToken.sol";
import "../contracts/CurrencyToken.sol";

//@title 完整的对抽签配售程序的测试用例
//项目为4000平米，最小拆分单位为0.01平
//其中3000平米面向公众出售，认购最小单位为0.1平米，每单位认购价500元
contract LotteryTest_3000_6329 is ContractReceiver {
    event TestEvent(bool indexed result, string message);

    //总预售平米
    uint total = 30000;
    //认购份额
    uint purchase = 63295;
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    LotteryTester tester = new LotteryTester();
    //初始化资产{名称，拆分小数点位数，总平米，资产初始拥有者}
    IREToken asset = new IREToken("Test", 2, 400000);
    //抽签预售程序{总预售平米数，拆分小数点位数，单价，单用户上限}
    //注：单用户申购上限测试用例参见LotteryTestPurchase.sol
    Lottery lottery = new Lottery(total, 1, 500, 70000, asset, cny);

    //第一步：资产3000平米转入预售合约，发行货币2亿元给认购类，启动认购后，认购类认购30000份
    //注：资产份额最小单位为0.01平，所以转入转出等均以0.01计
    function test1() public {
        asset.transfer(lottery, 3000 * 100);
        uint amt = 2 * 10000 * 10000;
        cny.mint(amt);
        cny.transfer(tester, amt);
        lottery.start();
        //认购前账户余额2亿
        Assert.equal(cny.balanceOf(tester), 2 * 10000 * 10000, "余额应为200000000");
        //认购30000份
        tester.purchase(cny, lottery, 100000, 30000, 500);
        //余额1.75亿元
        Assert.equal(cny.balanceOf(tester), 185000000, "余额应为175000000");
    }


    //第二步：追加认购33295份
    function test2() public {
        tester.purchase(cny, lottery, 100000, 33295, 500);
        //余额应为1.68亿元
        Assert.equal(cny.balanceOf(tester), 168352500, "余额应为168352500");
        //关闭认购
        lottery.close();
        //抽签
        lottery.draw();
    }

    //第三步：校验抽签结果
    function test3() public {
        tester.initialize(lottery);
        //抽签尾号为1，2，3，4，5位均有
        Assert.equal(lottery.getExponents(), 54321, "尾号范围应该为54321");
        Assert.equal(tester.validateNumbers(), true, "摇出号码有重号");
        //摇号结果需匹配总号数
        Assert.equal(tester.validateTotal(total, purchase), true, "结果无法满足条件");
    }

    //第四步：计算份额，并校验剩余须退认购款和余额和资产份额
    function test4() public {
        lottery.calculateShares();
        uint shares;
        uint cashLeft;
        (shares, cashLeft) = lottery.sharesOf(tester);
        Assert.equal(shares, 30000, "申购成功份额应为30000");
        Assert.equal(cashLeft, 16647500, "剩余申购款应为16647500");
        Assert.equal(cny.balanceOf(tester), 168352500, "余额应为168352500");
        Assert.equal(asset.balanceOf(tester), 0, "份额应为0");
    }

    //第五步：分配份额，校验份额数和账户余额
    function test5() public {
        lottery.allocateShares();
        //总份额应为3000平米，即300000份
        Assert.equal(asset.balanceOf(tester), 300000, "份额应为300000");
        //账户余额应为1.85亿元，2亿元-认购1500万
        Assert.equal(cny.balanceOf(tester), 185000000, "余额应为185000000");
        //总申购款
        Assert.equal(cny.balanceOf(this), 15000000, "出售总价不是15000000");
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}
