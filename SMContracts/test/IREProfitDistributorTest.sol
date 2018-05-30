pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NamingRepository.sol";
import "../contracts/IREToken.sol";
import "../contracts/CurrencyToken.sol";
import "../contracts/IREProfitDistributor.sol";
import "../contracts/MockERC20Account.sol";


//租金发放测试，发放租金前须向租金发放合约地址转入租金
contract IREProfitDistributorTest is ContractReceiver {
    IREToken asset = new IREToken("Test", 2, 100000);
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    MockERC20Account acc = new MockERC20Account(cny);
    NamingRepository repository = new NamingRepository();
    IREProfitDistributor payer = new IREProfitDistributor(repository, 10000);

    function test1() public {
        repository.setContract("CurrencyToken", 0, cny);
        repository.setContract("AssetToken", 10000, asset);
        //2000个账户压力测试
        asset.transfer(acc, 2000);
        Assert.equal(asset.balanceOf(acc), 2000, "份额不是2000");
        Assert.equal(cny.balanceOf(acc), 0, "余额不为0");

        for (uint i = 0; i < 1000; i++) {
            asset.transfer(address(i), 1);
        }

        payer.pay(1);
        Assert.equal(cny.balanceOf(acc), 0, "余额不为0");

        cny.mint(1000000);
        cny.approve(payer, 110000);
        Assert.equal(cny.allowance(this, payer), 110000, "余额不为110000");

        payer.pay(2);
        Assert.equal(cny.allowance(this, payer), 10000, "余额不为10000");
        Assert.equal(cny.balanceOf(acc), 2000, "余额不为2000");
        Assert.equal(cny.balanceOf(address(888)), 1, "余额不为1");
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}
