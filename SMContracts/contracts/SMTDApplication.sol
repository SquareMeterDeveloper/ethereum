pragma solidity ^0.4.0;

import '../contracts/NamingRepository.sol';
import '../contracts/CurrencyToken.sol';
import '../contracts/IRE721.sol';

///@title 平方米区块链去中心化程序主入口
contract SMTDApplication is Owned {
    NamingController controller;
    ERC20 cny;
    IRE721 token721;

    function SMTDApplication(){
        controller = new NamingRepository();
        cny = new CurrencyToken("CNYT", 6, 0);
        token721 = new IRE721();
        controller.setContract("ERC20", 0, cny);
        controller.setContract("ERC721", 0, token721);

        cny.changeOperator(msg.sender);
        cny.transferOwnership(msg.sender);


        token721.changeOperator(msg.sender);
        token721.transferOwnership(msg.sender);

        controller.changeOperator(msg.sender);
        controller.transferOwnership(msg.sender);
    }

    function namingController() public returns (address){
        return controller;
    }
}
