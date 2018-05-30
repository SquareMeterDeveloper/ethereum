pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import '../contracts/Owned.sol';
import "../contracts/ContractReceiver.sol";
import '../contracts/ERC20Dealer.sol';
import "../contracts/NamingController.sol";

//@title资产发售合约
//资产发售状态决定是否允许购买
//用户购买通过向该合约转入对应资金完成，支持多次购买，同时对单个用户累计可购买量设置上限
//售出份额满足一定比例后则发售成功，否则发售失败。
contract IRETDealer is ERC20Dealer, ContractReceiver {
    //用户账号和购买数量
    struct UserAccountMapping {
        //映射表
        address[] keys;
        mapping(address => UserAccount) map;
    }

    //用户认购账号
    struct UserAccount {
        //标识位
        bool flag;
        //用户购买记录，允许多次认购所以这里是数组
        uint[] purchased;
    }

    //状态标识
    int status = - 1;
    //用户认购配号，定金和中签结果
    UserAccountMapping accounts;

    //
    uint tokenId;
    //资产合约
    NamingController nc;
    //总发售量
    uint total;
    //发售份额乘数
    uint decimals;
    //单价
    uint price;
    //单用户购买上限
    uint limit;
    //发售成功比例界定
    uint percent;
    //总认购份数
    uint totalPurchased;

    //@dev 资产发售程序
    //@param _nc 合约控制器
    //@param _tokenId 资产tokenId
    //@param _total 总份额数
    //@param _decimals 资产分割粒度倍数
    //@param _price 单价（注：可能不是每平米价格）
    //@param _limit 用户限额
    //@param _percent 发售成功百分比标志
    function IRETDealer(NamingController _nc, uint _tokeId, uint _total, uint _decimals, uint _price, uint _limit, uint _percent) public {
        require(_percent < 100);
        require(_limit <= _total);
        nc = _nc;
        tokenId = _tokeId;
        total = _total;
        decimals = _decimals;
        price = _price;
        limit = _limit;
        percent = _percent;
    }

    function getAsset() private returns (ERC20){
        return ERC20(nc.getContract("AssetToken", tokenId));
    }

    function getCny() private returns (ERC20){
        return ERC20(nc.getContract("CurrencyToken", 0));
    }


    //@dev 启动认购
    function start() onlyOperator() public {
        if (status == - 1) {
            ERC20 asset = getAsset();
            //检查当前合约资产余额需等于发售量
            uint balance = asset.allowance(msg.sender, this);
            uint t = balance / (10 ** (asset.decimals() - decimals));
            if (t != total) {
                Start(msg.sender, 1);
            }
            else if (asset.transferFrom(msg.sender, this, balance)) {
                status = 0;
                Start(msg.sender, 0);
            } else {
                Start(msg.sender, 1);
            }
        } else {
            //已启动
            if (status == 0)
                Start(msg.sender, 2);
            //已关闭
            if (status > 0)
                Start(msg.sender, 3);
        }
    }

    //@dev 关闭发售
    function close() onlyOperator() public {
        if (status == 0) {
            if (totalPurchased * 100 / total > percent) {
                allocateShares();
            }
            else {
                finalize();
            }
            Close(msg.sender, 0);
        } else {
            Close(msg.sender, 1);
        }
    }

    //@dev 分配份额并退回剩余认购款
    function allocateShares() onlyOperator() private {
        ERC20 asset = getAsset();
        ERC20 currency = getCny();
        for (uint i = 0; i < accounts.keys.length; i++) {
            address user = accounts.keys[i];
            for (uint j = 0; j < accounts.map[user].purchased.length; j++) {
                uint purchased = accounts.map[user].purchased[j];
                uint shares = purchased * 10 ** (asset.decimals() - decimals);
                asset.transfer(user, shares);
            }
        }
        uint balance = currency.balanceOf(this);
        currency.transfer(msg.sender, balance);
        uint left = getTotalLeft();
        if (left > 0) {
            asset.transfer(msg.sender, left * 10 ** (asset.decimals() - decimals));
        }
        status = 2;
    }

    function finalize() onlyOperator() public {
        if (status < 1) {
            ERC20 asset = getAsset();
            ERC20 currency = getCny();
            uint balance = asset.balanceOf(this);
            if (balance > 0)
                asset.transfer(msg.sender, balance);
            for (uint i = 0; i < accounts.keys.length; i++) {
                address user = accounts.keys[i];
                for (uint j = 0; j < accounts.map[user].purchased.length; j++) {
                    uint purchased = accounts.map[user].purchased[j];
                    currency.transfer(user, purchased * price);
                }
            }
            status = 3;
            Finalize(msg.sender, 0);
        }
        else {
            Finalize(msg.sender, 1);
        }
    }

    function isClosed() public returns (bool){
        return status > 1;
    }

    function isFailed() public returns (bool){
        return status >= 3;
    }

    //@dev 计算用户剩余可购买份额
    function getUserLeft(address user) public view returns (uint){
        uint userTotal;
        UserAccount storage amt = accounts.map[user];
        for (uint i = 0; i < amt.purchased.length; i++) {
            uint u = amt.purchased[i];
            userTotal += u;
        }
        return limit - userTotal;
    }

    //@dev 计算剩余可认购份额
    function getTotalLeft() public view returns (uint){
        return total - totalPurchased;
    }

    function getDecimals() public view returns (uint){
        return decimals;
    }

    function getPrice() public view returns (uint){
        return price;
    }

    function getUserLimit() public view returns (uint){
        return limit;
    }

    function getStatus() public view returns (int){
        return status;
    }

    function getPercent() public view returns (uint){
        return percent;
    }

    ///@dev 总分配份额
    function getTotalShares() public view returns (uint){
        return total;
    }

    ///@dev 总认购份额数
    function getTotalPurchased() public view returns (uint){
        return totalPurchased;
    }

    ///@dev 返回用户所中份额和剩余预缴款
    function getPurchased(address adr) public view returns (uint){
        uint[] storage purchased = accounts.map[adr].purchased;
        uint shares;
        for (uint i = 0; i < purchased.length; i++) {
            uint n = purchased[i];
            shares += n;
        }
        return shares;
    }

    function getUsers() public view returns (address[]){
        return accounts.keys;
    }

    function purchase(uint amount) external returns (bool){
        if (status == 0) {
            address sender = msg.sender;
            uint totalLeft = getTotalLeft();
            uint userLeft = getUserLeft(sender);
            uint left = totalLeft > userLeft ? userLeft : totalLeft;
            uint purchased = left > amount ? amount : left;
            if (purchased == 0) {
                Purchase(sender, 2);
                return false;
            }
            else {
                uint value = purchased * price;
                ERC20 currency = getCny();
                uint allowance = currency.allowance(sender, this);
                if (allowance < value) {
                    Purchase(sender, 1);
                    return false;
                }
                else if (currency.transferFrom(sender, this, value)) {
                    UserAccount storage account = accounts.map[sender];
                    if (!account.flag) {
                        account.flag = true;
                        accounts.keys.push(sender);
                    }
                    account.purchased.push(purchased);
                    totalPurchased += purchased;
                    Purchase(sender, 0);
                    return true;
                }
                else {
                    Purchase(sender, 1);
                    return false;
                }
            }
        }
        else {
            Purchase(msg.sender, 3);
        }
    }

    function tokenFallback(address sender, uint value, address _token) public returns (uint){
        if (sender != address(0) && _token != address(0))
            return value;
        return 0;
    }
}
