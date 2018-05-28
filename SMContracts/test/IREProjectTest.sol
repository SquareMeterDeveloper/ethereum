pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Owned.sol";
import "../contracts/IREProject.sol";
import "../contracts/IRETDealer.sol";
import "../contracts/MockERC721Council.sol";
import "../contracts/NamingRepository.sol";
import '../contracts/IRE721.sol';

contract IREProjectTest is ContractReceiver {
    NamingRepository repository = new NamingRepository();
    MockERC721Council council = new MockERC721Council();
    IRE721 asset = new IRE721();
    IREProject project = new IREProject(
        repository,
        10000);

    function test1() public {
        /*project.start("SMT001",
            330000,
            2,
            1,
            60,
            100000,
            100000,
            80);*/
        repository.setContract("ERC721", 0, asset);
        repository.setContract("ERC721Council", 0, council);
        repository.setContract("ERC721Project", 10000, project);

        Assert.equal(repository.getContract("ERC20", 10000), address(0), "Token应该未创建");
        /*address adr2 = project.token();
        address adr4 = project.token();

        Assert.equal(adr2, adr4, "Token不正确");

        Owned owned = Owned(adr2);
        Assert.equal(owned.getOwner(), address(this), "Token所有者不正确");

        IRETDealer dealer = IRETDealer(project.dealer());
        Assert.equal(dealer.getOwner(), address(this), "Dealer所有者不正确");
        Assert.equal(dealer.getPrice(), 600, "单价不正确");
        Assert.equal(dealer.getDecimals(), 1, "份额分割倍数不正确");
        Assert.equal(dealer.getTotalShares(), 23000, "总份额数不正确");
        Assert.equal(dealer.getUserLimit(), 10000, "用户最大上限不正确");

        IREProfitDistributor distributor = IREProfitDistributor(project.profitDistributor());
        Assert.equal(distributor.getOwner(), address(this), "Distributor所有者不正确");*/
    }

    /*function testCreateDealer() public {
        Assert.equal(repository.getContract("ERC20Dealer", 10000), address(0), "Dealer应该未创建");
        address adr1 = project.createDealer();
        address adr2 = project.dealer();
        address adr3 = project.createDealer();
        address adr4 = project.dealer();
        Assert.notEqual(adr1, address(0), "Dealer应只创建一次");
        Assert.equal(adr1, adr2, "Dealer不正确");
        Assert.equal(adr3, address(0), "Dealer应只创建一次");
        Assert.equal(adr2, adr4, "Dealer不正确");

        Owned owned = Owned(adr2);
        Assert.equal(owned.getOwner(), address(this), "所有者不正确");
    }*/

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}