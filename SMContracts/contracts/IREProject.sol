pragma solidity ^0.4.0;

import '../contracts/NamingController.sol';
import '../contracts/ERC721Project.sol';
import '../contracts/ERC721Council.sol';
import '../contracts/ERC20Dealer.sol';

contract IREProject is ERC721Project {
    //tokenId
    uint id;
    //符号代码SMTXXX
    string projectSymbol;
    //总份数
    uint totalShares;
    //资产分割最小单位10的倍数
    uint tokenDecimals;
    //预留份额
    uint reservation;
    //出售份额倍数
    uint decimalsOfDeal;
    //单价
    uint price;
    //单用户购买上限
    uint userMax;
    //最小发售总份额备份比
    uint totalMin;
    //项目状态
    uint status;
    NamingController nc;

    function IREProject(
        NamingController _nc,
        uint _tokenId) public {
        nc = _nc;
        id = _tokenId;
    }

    function tokenId() external view returns (uint){
        return id;
    }

    function commissionChanging(address from, address to, address sender) external returns (bool) {
        ERC721Council c = ERC721Council(nc.getContract("ERC721Council", 0));
        if (address(c) == msg.sender) {
            if (c.isMemberOf(to, sender)) {
                uint count = c.commissionCountOf(id);
                address comm = c.commissionAtOf(count - 1, id);
                if (to == comm) {
                    address t = nc.getContract("AssetToken", id);
                    address d = nc.getContract("AssetDealer", id);
                    if (t == address(0) || d == address(0))
                        return false;
                    ERC20Dealer dealer = ERC20Dealer(d);
                    return dealer.isClosed() && !dealer.isFailed();
                }
                if (from == comm) {
                    address p = nc.getContract("ProfitDistributor", id);
                    return p != address(0);
                }
            }
        }
        return false;
    }

    function commissionChanged(address from, address to, address sender) external returns (bool) {
        return true;
    }

    function liquidate() external returns (bool) {

    }
}
