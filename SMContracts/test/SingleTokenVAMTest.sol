pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CurrencyToken.sol";
import "../contracts/SingleTokenVAM.sol";
import "../contracts/MockERC20Account.sol";
import "../contracts/NamingRepository.sol";

contract SingleTokenVAMTest {
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    MockERC20Account ac1 = new MockERC20Account(cny);
    MockERC20Account ac2 = new MockERC20Account(cny);
    NamingRepository repository = new NamingRepository();

    function test1() public {
        repository.setContract("CurrencyToken", 0, cny);
        cny.mint(20000);
        cny.transfer(ac1, 10000);
        cny.transfer(ac2, 10000);
        SingleTokenVAM vam = new SingleTokenVAM(repository, "CurrencyToken", 0, ac1, 6000, ac2, 0);
        Assert.equal(vam.getPartyA(), ac1, '甲方地址不正确');
        Assert.equal(vam.getPartyB(), ac2, '乙方地址不正确');
        Assert.equal(vam.getStatus(), 0, '状态不正确');

        ac1.approve(vam, 6000);
        vam.start();
        Assert.equal(cny.balanceOf(vam), 6000, '注额应为6000');

        vam.execute(80, 100);
        Assert.equal(cny.balanceOf(ac1), 8800, '甲方余额不正确');
        Assert.equal(cny.balanceOf(ac2), 11200, '乙方余额不正确');
    }

    function test2() public {
        SingleTokenVAM vam = new SingleTokenVAM(repository, "CurrencyToken", 0, ac1, 6000, ac2, 3000);
        Assert.equal(vam.getPartyA(), ac1, '甲方地址不正确');
        Assert.equal(vam.getPartyB(), ac2, '乙方地址不正确');
        Assert.equal(vam.getStatus(), 0, '状态不正确');

        ac1.approve(vam, 6000);
        ac2.approve(vam, 3000);
        vam.start();
        Assert.equal(cny.balanceOf(vam), 9000, '注额应为9000');


        vam.execute(100, 100);
        Assert.equal(cny.balanceOf(ac1), 11800, '甲方余额不正确');
        Assert.equal(cny.balanceOf(ac2), 8200, '乙方余额不正确');
    }
}
