pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IRECouncil.sol";
import "../contracts/NamingRepository.sol";
import '../contracts/MockERC721Project.sol';
import '../contracts/IRE721.sol';

contract CouncilTakeReleaseTest {
    NamingRepository repository = new NamingRepository();
    IRECouncil council = new IRECouncil(repository);
    IRE721 asset = new IRE721();
    MockERC721Project tester = new MockERC721Project();


    function testTakeAndRelease() public {
        repository.setContract("ERC721", 0, asset);
        repository.setContract("ERC721Project", tester.tokenId(), tester);
        asset.create(tester.tokenId());
        asset.transfer(council, tester.tokenId());
        council.add(address(1));
        council.add(address(2));
        council.add(address(3));
        council.add(address(4));
        council.add(address(5));
        council.add(this);
        council.addMember(this);

        council.init(tester.tokenId(),25);
        council.next(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(3), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(3)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(this)), 1, "下一委员会Token数不正确");

        council.take(tester.tokenId());
        Assert.equal(council.memberOf(tester.tokenId()), address(this), "当前所属委员会成员不正确");
        Assert.equal(council.tokenCountOf(address(3)), 1, "委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(this)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfMember(address(this)), 1, "当前Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(this)), 1, "下一委员会Token数不正确");

        council.release(tester.tokenId());
        Assert.equal(council.tokenCountOfMember(address(this)), 0, "当前Token数不正确");
        Assert.equal(council.memberOf(tester.tokenId()), address(0), "当前所属委员会成员不正确");
    }

    function testLiquidate() public {
        council.add(address(888));
        council.liquidate(tester.tokenId());
        Assert.equal(tester.isLiquidated(), true, "已清算状态不正确");
        Assert.equal(council.commissionOf(tester.tokenId()), address(1), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(1)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(1)), 1, "下一委员会Token数不正确");
    }
}
