pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NamingRepository.sol";
import "../contracts/CurrencyToken.sol";
import "../contracts/TokenDistributor.sol";

contract TokenDistributorTest {
    CurrencyToken cny = new CurrencyToken("CNYT", 6, 0);
    NamingRepository repository = new NamingRepository();
    TokenDistributor distributor = new TokenDistributor(repository);

    function test1() public {
        repository.setContract("CurrencyToken", 0, cny);

        cny.mint(100000);
        cny.approve(distributor, 100000);

        address[] memory users = new address[](3);
        users[0] = address(111);
        users[1] = address(222);
        users[2] = address(333);

        uint[] memory amount = new uint[](3);
        amount[0] = 10000;
        amount[1] = 20000;
        amount[2] = 30000;

        distributor.transfer("CurrencyToken", 0, 876, users, amount);

        Assert.equal(cny.balanceOf(address(111)), 10000, "余额不为10000");
        Assert.equal(cny.balanceOf(address(222)), 20000, "余额不为20000");
        Assert.equal(cny.balanceOf(address(333)), 30000, "余额不为30000");

        Assert.equal(cny.allowance(this, distributor), 40000, "余额不为40000");
    }
}