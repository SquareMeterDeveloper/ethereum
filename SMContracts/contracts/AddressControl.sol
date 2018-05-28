pragma solidity ^0.4.0;

contract AddressControl {
    modifier isSenderNotContract() {
        uint length;
        address addr = msg.sender;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(addr)
        }
        require(length == 0);
        _;
    }

    modifier isSenderContract() {
        uint length;
        address addr = msg.sender;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(addr)
        }
        require(length > 0);
        _;
    }
}
