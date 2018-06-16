pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IRECouncil.sol";
import "../contracts/NamingRepository.sol";
import '../contracts/MockERC721Project.sol';
import '../contracts/IRE721.sol';

contract CouncilInitTest {
    NamingRepository repository = new NamingRepository();
    IRECouncil council = new IRECouncil(repository);
    IRE721 asset = new IRE721();
    //MockERC721Project tester = new MockERC721Project();

    function test() public {
        repository.setContract("ERC721", 0, asset);
        //repository.setContract("ERC721Project", tester.tokenId(), tester);
        asset.create(1);
        asset.transfer(council, 1);
        council.add(address(1));
        council.add(address(2));
        council.add(address(3));
        council.add(address(4));
        council.add(address(5));
        council.add(address(6));
        council.add(address(7));
        council.add(address(8));
        council.add(address(9));
        council.add(address(10));
        council.init(1, 5394);

        Assert.equal(council.commissionCountOf(1), 4, "委员会初始化失败");

        Assert.equal(council.commissionAtOf(1, 0), address(6), "委员会初始化失败");
        Assert.equal(council.commissionAtOf(1, 1), address(4), "委员会初始化失败");
        Assert.equal(council.commissionAtOf(1, 2), address(10), "委员会初始化失败");
        Assert.equal(council.commissionAtOf(1, 3), address(5), "委员会初始化失败");
        //Assert.equal(council.stateAt(1, 4), 4, "委员会初始化失败");
    }
}

