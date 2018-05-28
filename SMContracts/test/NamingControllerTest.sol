pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NamingRepository.sol";

contract NamingControllerTest is Owned {

    NamingRepository controller = new NamingRepository();

    function test1() public {
        Assert.equal(controller.getContract("AAAA", 0), address(0), "地址不正确");
        controller.setContract("AAAA", 0, this);

        Assert.equal(controller.getContract("AAAA", 0), address(this), "地址不正确");
        controller.setContract("AAAA", 1, this);
        Assert.equal(controller.getContract("AAAA", 1), address(this), "地址不正确");
    }
}
