pragma solidity ^0.4.0;

import '../contracts/VAM.sol';
import '../contracts/ContractReceiver.sol';
import '../contracts/ERC20.sol';
import "../contracts/NamingController.sol";
//@dev 双方对赌协议
contract SingleTokenVAM is VAM, ContractReceiver {
    address partyA;
    address partyB;
    uint amountA;
    uint amountB;
    uint valueA;
    uint valueB;
    uint status;
    NamingController nc;
    string name;
    uint key;

    function SingleTokenVAM(NamingController _nc, string _name, uint _key, address _partyA, uint _amountA, address _partyB, uint _amountB) public {
        require(_partyA != _partyB);
        require(_amountA > 0 || _amountB > 0);
        nc = _nc;
        name = _name;
        key = _key;
        partyA = _partyA;
        amountA = _amountA;
        partyB = _partyB;
        amountB = _amountB;
    }

    function start() onlyOperator external {
        if (status == 0) {
            ERC20 token = ERC20(nc.getContract(name, key));
            if (amountA > 0) {
                uint aA = token.allowance(partyA, this);
                if (aA < amountA || !token.transferFrom(partyA, this, amountA)) {
                    Start(msg.sender, 1);
                    return;
                }
            }
            if (amountB > 0) {
                uint aB = token.allowance(partyB, this);
                if (aB < amountB || !token.transferFrom(partyB, this, amountB)) {
                    Start(msg.sender, 2);
                    return;
                }
            }
            status = 1;
            Start(msg.sender, 0);
        }
        else {
            Start(msg.sender, 3);
        }
    }


    function execute(uint _valueA, uint _valueB) onlyOperator external {
        if (status == 1) {
            ERC20 token = ERC20(nc.getContract(name, key));
            valueA = _valueA;
            valueB = _valueB;
            if (valueA >= valueB) {
                token.transfer(partyA, amountB + amountA);
            } else {
                uint amount = amountA * valueA / valueB;
                token.transfer(partyA, amount);
                token.transfer(partyB, amountA + amountB - amount);
            }
            status = 2;
            Execute(msg.sender, 0);
        }
        else {
            Execute(msg.sender, 1);
        }
    }

    function getPartyA() public view returns (address){
        return partyA;
    }

    function getPartyB() public view returns (address){
        return partyB;
    }

    function getAmountOfA() public view returns (uint){
        return amountA;
    }

    function getAmountOfB() public view returns (uint){
        return amountB;
    }

    function getValueA() public view returns (uint){
        return valueA;
    }

    function getValueB() public view returns (uint){
        return valueB;
    }

    function getStatus() public view returns (uint){
        return status;
    }

    function tokenFallback(address sender, uint value, address _token) public returns (uint){
        if (sender != address(0) && _token != address(0))
            return value;
        return 0;
    }
}
