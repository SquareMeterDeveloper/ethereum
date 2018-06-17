pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IRECouncil.sol";
import "../contracts/NamingRepository.sol";
import '../contracts/MockERC721Project.sol';
import '../contracts/IRE721.sol';

contract CouncilFirstTakeTest {
    NamingRepository repository = new NamingRepository();
    IRECouncil council = new IRECouncil(repository);
    IRE721 asset = new IRE721();
    MockERC721Project tester = new MockERC721Project();

    function testTake() public {
        repository.setContract("ERC721", 0, asset);
        repository.setContract("ERC721Project", tester.tokenId(), tester);
        asset.create(tester.tokenId());
        asset.transfer(council, tester.tokenId());
        council.add(address(1));
        council.add(this);
        council.addMember(this);
        council.add(address(2));
        council.add(address(3));
        council.add(address(4));
        council.add(address(5));

        council.init(tester.tokenId(), 12);
        council.take(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(0), "当前委员会不正确");
        Assert.equal(council.memberOf(tester.tokenId()), address(this), "当前所属委员会成员不正确");
    }
}
