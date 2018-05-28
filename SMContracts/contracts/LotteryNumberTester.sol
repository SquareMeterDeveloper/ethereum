pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import "../contracts/ContractReceiver.sol";

contract LotteryNumberTester is ContractReceiver {
    ///用户账号和号段映射表
    struct UserAccountMapping {
        //映射表
        address[] keys;
        mapping(address => UserAccount) map;
    }

    //用户认购账号
    struct UserAccount {
        //标识位
        bool flag;
        //用户认购记录，允许多次认购所以这里是数组
        UserNumbers[] numbers;
    }

    //用户配号记
    //注：Max-Min+1是用户的配号数量
    struct UserNumbers {
        //最小号
        uint min;
        //最大号
        uint max;
        //预存款
        uint cash;
        //时间戳
        uint timeStamp;
        //中签数量
        uint shares;
        //剩余金额
        uint cashLeft;
    }

    //余额token
    ERC20 cnyToken;
    //用户认购配号，定金和中签结果
    UserAccountMapping accounts;

    function LotteryNumberTester(ERC20 _cnyToken) public {
        cnyToken = _cnyToken;
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (token != address(cnyToken)) {
            return 0;
        }
        else {
            UserAccount storage account = accounts.map[sender];
            if (!account.flag) {
                account.flag = true;
                accounts.keys.push(sender);
                account.numbers.push(UserNumbers(0, 0, value, 0, 0, 0));
            }
            else {
                bool flag = false;
                for (uint i = 0; i < account.numbers.length; i++) {
                    if (account.numbers[i].timeStamp == 0) {
                        account.numbers[i].cash += value;
                        flag = true;
                    }
                }
                if (!flag) {
                    account.numbers.push(UserNumbers(0, 0, value, 0, 0, 0));
                }
            }
            return value;
        }
    }

    ///@dev 是否已转入资金
    function hasTransfer(address adr) public view returns (bool){
        return accounts.map[adr].flag;
    }
}
