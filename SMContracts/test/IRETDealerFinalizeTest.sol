pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IRETDealer.sol";
import "../contracts/NamingRepository.sol";
import "../contracts/IRETDealer.sol";
import "../contracts/IREToken.sol";
import "../contracts/CurrencyToken.sol";

//@title 完整的对抽签配售程序的测试用例
//项目为4000平米，最小拆分单位为0.01平
//其中3000平米面向公众出售，认购最小单位为0.1平米，每单位认购价500元
contract IRETDealerFinalizeTest is ContractReceiver {
    event TestEvent(bool indexed result, string message);

    //总预售平米
    uint total = 30000;
    //认购份额
    uint purchase = 63295;
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    //初始化资产{名称，拆分小数点位数，总平米，资产初始拥有者}
    IREToken asset = new IREToken("SMT01", 2, 400000);
    NamingRepository repository = new NamingRepository();
    //抽签预售程序{总预售平米数，拆分小数点位数，单价，单用户上限}
    //注：单用户申购上限测试用例参见LotteryTestPurchase.sol
    IRETDealer store = new IRETDealer(repository, 10000, total, 1, 600, 25000, 80);

    function test1() public {
        repository.setContract("AssetToken", 10000, asset);
        repository.setContract("CurrencyToken", 0, cny);
        asset.approve(store, 3000 * 100);
        uint amt = 2 * 10000 * 10000;
        cny.mint(amt);
        cny.transfer(this, amt);
        store.start();
        //认购前账户余额2亿
        Assert.equal(cny.balanceOf(this), 2 * 10000 * 10000, "余额应为200000000");
        //购买前份额数
        Assert.equal(asset.balanceOf(store), 300000, "资产份数不是300000");
        //认购10000份
        cny.approve(store, 6000000);
        store.purchase(10000);
        //余额1.94亿元
        Assert.equal(cny.balanceOf(this), 194000000, "余额应为194000000");
        Assert.equal(store.getPurchased(this), 10000, "已购买份数不是10000");
        Assert.equal(store.getTotalLeft(), 20000, "剩余可购份数不是20000");
        Assert.equal(store.getUserLeft(this), 15000, "剩余可购份数不是10000");

        //认购10000份
        cny.approve(store, 6000000);
        store.purchase(10000);
        Assert.equal(cny.balanceOf(this), 188000000, "余额应为188000000");
        Assert.equal(store.getPurchased(this), 20000, "已购买份数不是20000");
        Assert.equal(store.getTotalLeft(), 10000, "剩余可购份数不是10000");
        Assert.equal(store.getUserLeft(this), 5000, "剩余可购份数不是5000");
        store.close();

        //store.allocateShares();
        Assert.equal(cny.balanceOf(this), 200000000, "余额应为200000000");
        Assert.equal(asset.balanceOf(this), 400000, "资产数应为400000");
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}
