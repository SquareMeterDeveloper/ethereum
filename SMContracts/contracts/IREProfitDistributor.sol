pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import '../contracts/ERC721ProfitDistributor.sol';
import '../contracts/ContractReceiver.sol';
import "../contracts/NamingController.sol";

contract IREProfitDistributor is ERC721ProfitDistributor {
    NamingController nc;
    uint tokenId;

    function IREProfitDistributor(NamingController _nc, uint _tokenId) public {
        nc = _nc;
        tokenId = _tokenId;
    }

    function naming() public view returns (address){
        return nc;
    }

    function getTokenId() public view returns (uint){
        return tokenId;
    }

    //分配租金根据持股数和合约资金账户余额进行租金分配
    //注：租金属于该合约的账户，充值需冲入该合约地址，分配租金是逐笔转账的过程
    function pay(uint taskId) onlyOperator() external {
        ERC20 cnyToken = getCny();
        ERC20 ireToken = getAsset();
        uint balance = cnyToken.allowance(msg.sender, this);
        uint totalShares = ireToken.totalSupply();
        uint total;
        if (balance > 0) {
            uint holders = ireToken.holdersCount();
            for (uint i = 0; i < holders; i++) {
                address adr;
                uint shares;
                (adr, shares) = ireToken.holderAt(i);
                uint amount = balance * shares / totalShares;
                total += amount;
                if (shares > 0) {
                    cnyToken.transferFrom(msg.sender, adr, amount, taskId);
                }
            }
            Pay(msg.sender, taskId, total, balance - total, 0);
        } else {
            Pay(msg.sender, taskId, 0, 0, 1);
        }
    }

    function getCny() public returns (ERC20) {
        return ERC20(nc.getContract("CurrencyToken", 0));
    }

    function getAsset() public returns (ERC20){
        return ERC20(nc.getContract("AssetToken", tokenId));
    }
}
