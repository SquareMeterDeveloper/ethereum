pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IRECouncil.sol";
import "../contracts/NamingRepository.sol";
import '../contracts/IRE721.sol';

contract CouncilTest {
    NamingRepository repository = new NamingRepository();
    IRECouncil council = new IRECouncil(repository);
    IRE721 asset = new IRE721();

    function testAddRemove() public {
        repository.setContract("ERC721", 0, asset);
        //repository.setContract("ERC721Project", 10000, this);
        //asset.create(10000);
        //asset.transfer(committee, 10000);
        council.add(address(1));
        Assert.equal(council.commissionCount(), 1, "数量不正确");
        council.add(address(2));
        Assert.equal(council.commissionCount(), 2, "数量不正确");
        council.add(address(3));
        Assert.equal(council.commissionCount(), 3, "数量不正确");
        council.add(address(4));
        Assert.equal(council.commissionCount(), 4, "数量不正确");
        council.add(address(5));
        Assert.equal(council.commissionCount(), 5, "数量不正确");
        Assert.equal(council.commissionAt(0), address(1), "顺序不正确");
        Assert.equal(council.commissionAt(1), address(2), "顺序不正确");
        Assert.equal(council.commissionAt(2), address(3), "顺序不正确");
        Assert.equal(council.commissionAt(3), address(4), "顺序不正确");
        Assert.equal(council.commissionAt(4), address(5), "顺序不正确");

        council.remove(address(1));
        Assert.equal(council.commissionCount(), 4, "数量不正确");
        Assert.equal(council.commissionAt(0), address(2), "顺序不正确");
        Assert.equal(council.commissionAt(1), address(3), "顺序不正确");
        Assert.equal(council.commissionAt(2), address(4), "顺序不正确");
        Assert.equal(council.commissionAt(3), address(5), "顺序不正确");

        council.remove(address(3));
        Assert.equal(council.commissionCount(), 3, "数量不正确");
        Assert.equal(council.commissionAt(0), address(2), "顺序不正确");
        Assert.equal(council.commissionAt(1), address(4), "顺序不正确");
        Assert.equal(council.commissionAt(2), address(5), "顺序不正确");

        council.add(address(6));
        Assert.equal(council.commissionCount(), 4, "数量不正确");
        Assert.equal(council.commissionAt(0), address(2), "顺序不正确");
        Assert.equal(council.commissionAt(1), address(4), "顺序不正确");
        Assert.equal(council.commissionAt(2), address(5), "顺序不正确");
        Assert.equal(council.commissionAt(3), address(6), "顺序不正确");

        council.remove(address(6));
        Assert.equal(council.commissionCount(), 3, "数量不正确");
        Assert.equal(council.commissionAt(0), address(2), "顺序不正确");
        Assert.equal(council.commissionAt(1), address(4), "顺序不正确");
        Assert.equal(council.commissionAt(2), address(5), "顺序不正确");
    }

    function testInsertCommittee() public {
        council.insert(2, address(7));
        Assert.equal(council.commissionCount(), 4, "数量不正确");
        Assert.equal(council.commissionAt(0), address(2), "顺序不正确");
        Assert.equal(council.commissionAt(1), address(4), "顺序不正确");
        Assert.equal(council.commissionAt(2), address(7), "顺序不正确");
        Assert.equal(council.commissionAt(3), address(5), "顺序不正确");
    }

    function testAddRemoveMember() public {
        council.add(this);

        council.addMember(address(11));
        Assert.equal(council.memberCountOf(this), 1, "数量不正确");
        Assert.equal(council.isMemberOf(this, address(11)), true, "应该是委员会成员");
        council.addMember(address(12));
        Assert.equal(council.memberCountOf(this), 2, "数量不正确");
        council.addMember(address(13));
        Assert.equal(council.memberCountOf(this), 3, "数量不正确");
        council.addMember(address(14));
        Assert.equal(council.memberCountOf(this), 4, "数量不正确");
        council.addMember(address(15));
        Assert.equal(council.memberCountOf(this), 5, "数量不正确");

        council.removeMember(address(11));
        Assert.equal(council.memberCountOf(this), 4, "数量不正确");
        Assert.equal(council.isMemberOf(this, address(11)), false, "应该已经不是委员会成员");

        council.removeMember(address(13));
        Assert.equal(council.memberCountOf(this), 3, "数量不正确");

        council.removeMember(address(15));
        Assert.equal(council.memberCountOf(this), 2, "数量不正确");
    }
}
