pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Owned.sol";
import "../contracts/IREProject.sol";
import "../contracts/IRETDealer.sol";
import "../contracts/IRECouncil.sol";
import "../contracts/NamingRepository.sol";
import '../contracts/IRE721.sol';

contract IREProjectTest is ContractReceiver {
    NamingRepository repository = new NamingRepository();
    IRECouncil council = new IRECouncil(repository);
    IRE721 asset = new IRE721();
    IREProject project = new IREProject(repository, 10000);

    function testNext() public {
        repository.setContract("ERC721", 0, asset);
        repository.setContract("ERC721Council", 0, council);
        repository.setContract("ERC721Project", project.tokenId(), project);
        asset.create(project.tokenId());
        asset.transfer(council, project.tokenId());
        council.add(address(1));
        council.add(this);
        council.addMember(this);
        council.add(address(2));
        council.add(address(3));
        council.add(address(4));
        council.add(address(5));

        council.init(project.tokenId(), 12);
        council.take(project.tokenId());
        council.next(project.tokenId());
        Assert.equal(council.commissionOf(project.tokenId()), address(this), "当前委员会不正确");
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}