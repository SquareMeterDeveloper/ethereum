pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SMTDApplication.sol";
import '../contracts/IRECouncil.sol';

contract SMTDApplicationTest {
    SMTDApplication app = new SMTDApplication();
    function testInitialize() public {
        NamingController controller = NamingController(app.namingController());

        Assert.notEqual(address(controller), address(0), "地址合约不存在");
        Assert.equal(controller.getOwner(), address(this), "Owner不正确");

        Assert.notEqual(controller.getContract("ERC20", 0), address(0), "CNYT合约不存在");
        Assert.notEqual(controller.getContract("ERC721", 0), address(0), "ERC721不存在");

        //IRECouncil council = new IRECouncil(controller);
        //controller.setContract("ERC721Council", 0, council);
        //Assert.notEqual(controller.getContract("ERC721Council", 0), address(0), "ERC721Council不存在");
    }
}
