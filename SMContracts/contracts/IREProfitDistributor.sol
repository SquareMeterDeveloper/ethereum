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

    function calculate(ERC20 cnyToken, ERC20 ireToken, address payer) private view returns (uint, uint, uint){
        uint balance = cnyToken.allowance(payer, this);
        //总份数=总平米数*分割倍数
        uint totalShares = ireToken.totalSupply();
        //计算每份需分配租金数，余数部分不分配
        uint amount = balance / totalShares;
        uint total = amount * totalShares;
        return (total, balance - total, amount);
    }

    //分配租金根据持股数和合约资金账户余额进行租金分配
    //注：租金属于该合约的账户，充值需冲入该合约地址，分配租金是逐笔转账的过程
    function pay(uint taskId) onlyOperator() external {
        ERC20 cnyToken = getCny();
        ERC20 ireToken = getAsset();
        uint total;
        uint residual;
        uint amt;
        (total, residual, amt) = calculate(cnyToken, ireToken, msg.sender);
        if (amt > 0) {
            uint holders = ireToken.holdersCount();
            for (uint i = 0; i < holders; i++) {
                address adr;
                uint shares;
                (adr, shares) = ireToken.holderAt(i);
                if (shares > 0) {
                    cnyToken.transferFrom(msg.sender, adr, shares * amt, taskId);
                }
            }
            Pay(msg.sender, taskId, total, residual, 0);
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
