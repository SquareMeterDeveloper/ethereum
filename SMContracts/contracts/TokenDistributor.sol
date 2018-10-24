pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import '../contracts/ERC721ProfitDistributor.sol';
import '../contracts/ContractReceiver.sol';
import "../contracts/NamingController.sol";

contract TokenDistributor is Owned {
    NamingController nc;

    event Transfer(address indexed from, uint indexed memo, uint code);

    function TokenDistributor(NamingController _nc) public {
        nc = _nc;
    }

    function naming() public view returns (address){
        return nc;
    }

    function transfer(string tokenName, uint key, uint memo, address[] users, uint[] amount) external {
        ERC20 token = ERC20(nc.getContract(tokenName, key));
        if (users.length != amount.length) {
            Transfer(msg.sender, memo, 2);
        } else {
            uint total = 0;
            for (uint j = 0; j < amount.length; j++) {
                total += amount[j];
            }
            uint approved = token.allowance(msg.sender, this);
            uint balance = token.balanceOf(msg.sender);
            if (approved < total || balance < total) {
                Transfer(msg.sender, memo, 1);
            }
            else {
                transfer(token, msg.sender, memo, users, amount);
            }
        }
    }

    function transfer(ERC20 token, address sender, uint memo, address[] users, uint[] amount) private {
        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            token.transferFrom(sender, user, amount[i], memo);
        }
        Transfer(msg.sender, memo, 0);
    }
}
