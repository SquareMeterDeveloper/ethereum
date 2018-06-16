pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IRECouncil.sol";
import "../contracts/NamingRepository.sol";
import '../contracts/MockERC721Project.sol';
import '../contracts/IRE721.sol';

contract CouncilNextTest {
    NamingRepository repository = new NamingRepository();
    IRECouncil council = new IRECouncil(repository);
    IRE721 asset = new IRE721();
    MockERC721Project tester = new MockERC721Project();

    function testNext() public {
        repository.setContract("ERC721", 0, asset);
        repository.setContract("ERC721Project", tester.tokenId(), tester);
        asset.create(tester.tokenId());
        asset.transfer(council, tester.tokenId());
        council.add(address(0));
        council.add(address(1));
        council.add(address(2));
        council.add(address(3));
        council.add(address(4));
        council.add(address(5));

        council.init(tester.tokenId(), 12345);

        council.next(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(1), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(0)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(1)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(2)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(1)), 0, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(2)), 1, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(3)), 0, "下一委员会Token数不正确");

        council.next(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(2), "当前委员会不正确");
        Assert.equal(council.nextCommissionOf(tester.tokenId()), address(3), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(1)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(2)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(3)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(2)), 0, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(3)), 1, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(4)), 0, "下一委员会Token数不正确");

        council.next(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(3), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(2)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(3)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(4)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(3)), 0, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(4)), 1, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(5)), 0, "下一委员会Token数不正确");

        council.next(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(4), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(3)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(4)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(5)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(4)), 0, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(5)), 1, "下一委员会Token数不正确");

        council.next(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(5), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(4)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(5)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(4)), 0, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(5)), 1, "下一委员会Token数不正确");

        council.next(tester.tokenId());
        Assert.equal(council.commissionOf(tester.tokenId()), address(5), "当前委员会不正确");
        Assert.equal(council.tokenCountOf(address(4)), 0, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOf(address(5)), 1, "当前委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(4)), 0, "下一委员会Token数不正确");
        Assert.equal(council.tokenCountOfNextCommission(address(5)), 1, "下一委员会Token数不正确");
    }
}

