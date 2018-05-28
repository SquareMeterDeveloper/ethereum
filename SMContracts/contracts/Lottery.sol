pragma solidity ^0.4.0;

import '../contracts/ERC20.sol';
import '../contracts/Owned.sol';
import "../contracts/ContractReceiver.sol";

///@title 项目发售摇号及分配份额程序
///根据每个认购用户时间戳生成随机种子后摇出随机签号
///摇号采用尾号匹配方式
///项目认购数不足，项目终止
///否则根据摇号结果分配份额，退回剩余预存款，发售成功。
contract Lottery is ContractReceiver, Owned {

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

    //摇号结果映射关系
    struct WinnerMapping {
        //尾号数作为Key
        uint[] keys;
        mapping(uint => Winners) map;
    }

    //摇出的尾号
    struct Winners {
        bool flag;
        uint[] numbers;
    }

    //总份数
    uint total;
    //小数点拆分
    uint decimals;
    //随机种子
    uint seedHash;
    //总认购份数
    uint totalPurchased;
    //单份价格
    uint unitPrice;
    //单用户限额
    uint userLimit;
    //转入资产的账户
    address assetOwner;
    //资产token
    ERC20 ireToken;
    //余额token
    ERC20 cnyToken;
    //状态标识
    int status;
    //摇号结果
    WinnerMapping winners;
    //用户认购配号，定金和中签结果
    UserAccountMapping accounts;

    ///发售流程：启动认购-认购-关闭认购-摇号-分配份额-终止
    event Start(address indexed from, string message, bool success);
    event Purchase(address indexed from, string message, uint amount, bool success);
    event Close(address indexed from, string message, bool success);
    event Draw(address indexed from, string message, bool success);
    event CalculateShares(address indexed from, string message, bool success);
    event AllocateShares(address indexed from, string message, bool success);
    event Finalize(address indexed from, string message, bool success);

    ///@dev 项目摇号程序，需要传入项目标识与项目进行关联
    ///@param _total 总份额数
    ///@param _decimals 资产分割粒度倍数
    ///@param _unitPrice 每份认购价（单位：分）。注：不是每平米价格
    ///@param _userLimit 用户限额
    function Lottery(
        uint _total,
        uint _decimals,
        uint _unitPrice,
        uint _userLimit,
        ERC20 _ireToken,
        ERC20 _cnyToken)
    public {
        require(_total > 0);
        require(_unitPrice > 0);
        decimals = _decimals;
        total = _total;
        unitPrice = _unitPrice;
        userLimit = _userLimit;
        status = - 1;
        ireToken = _ireToken;
        cnyToken = _cnyToken;
    }

    //@dev 启动认购
    function start() onlyOperator() public {
        if (status == - 1) {
            uint balance = ireToken.balanceOf(this);
            uint totalShares = balance / (10 ** (ireToken.decimals() - decimals));
            if (totalShares != total) {
                Start(msg.sender, "无法开启认购，原因：账户没有足够份额", false);
            }
            else {
                status = 0;
                Start(msg.sender, "启动成功", true);
            }
        } else {
            if (status == 0)
                Start(msg.sender, "无法开启认购,原因：认购已经开启", false);
            if (status > 0)
                Start(msg.sender, "无法开启认购,原因：认购已经关闭", false);
        }
    }

    ///@dev 用户认购
    ///@param timeStamp 时间戳
    ///@param amount 认购数量
    ///@return 起始配号
    function purchase(uint timeStamp, uint amount) public {
        if (status != 0) {
            Purchase(msg.sender, "认购失败，原因：认购未开启", 0, false);
            return;
        }
        if (timeStamp == 0) {
            Purchase(msg.sender, "认购失败，原因：时间戳不正确", 0, false);
            return;
        }
        if (amount == 0) {
            Purchase(msg.sender, "认购失败，原因：认购份额必须大于0", 0, false);
            return;
        }
        //根据总认购限额和单用户限额计算用户当前可认购最大数量，三种结果：
        //1.可认购数量为0，认购失败;
        //2.认购数量大于可认购数量,部分认购；
        //3.全额认购成功；
        //认购前需转入资金
        uint canPurchase = getUserLeft();
        if (canPurchase == 0) {
            Purchase(msg.sender, "认购超出限额", 0, false);
        }
        else if (amount > canPurchase) {
            if (doPurchase(canPurchase, timeStamp)) {
                updateHash(timeStamp);
                Purchase(msg.sender, "部分认购成功", canPurchase, true);
            } else {
                Purchase(msg.sender, "认购失败，原因：未转入足够资金", 0, false);
            }
        }
        else {
            if (doPurchase(amount, timeStamp)) {
                updateHash(timeStamp);
                Purchase(msg.sender, "认购成功", amount, true);
            } else {
                Purchase(msg.sender, "认购失败，原因：未转入足够资金", 0, false);
            }
        }
    }

    function updateHash(uint timeStamp) private {
        //用户账户，时间戳和认购数量计入hash作为随机种子
        if (totalPurchased == 0)
            seedHash = uint(keccak256(msg.sender, timeStamp));
        else
            seedHash = uint(keccak256(seedHash, msg.sender, timeStamp));
    }

    //@dev 认购份额
    //@param amount 份额数
    //@param timeStamp 时间戳
    function doPurchase(uint amount, uint timeStamp) private returns (bool){
        UserAccount storage account = accounts.map[msg.sender];
        if (!account.flag) {
            return false;
        }
        UserNumbers storage number = account.numbers[account.numbers.length - 1];
        if (number.timeStamp == 0) {
            //预存认购金额不足，退回所有金额，返回false
            uint totalNeeded = amount * unitPrice;
            if (number.cash < totalNeeded) {
                cnyToken.transfer(msg.sender, number.cash);
                number.cash = 0;
                return false;
            }
            //最小配号和最大配号的计算，最小配号为目前总申购份数加1
            number.min = totalPurchased + 1;
            //最大配号为最小配号加认购数量后减1
            number.max = totalPurchased + amount;
            //退回多余的认购款
            cnyToken.transfer(msg.sender, number.cash - totalNeeded);
            //总锁定金额
            number.cash = totalNeeded;
            //未开始抽签所以剩余要退回认购款为0
            number.cashLeft = 0;
            number.timeStamp = timeStamp;
            //总认购份额增加
            totalPurchased += amount;
            return true;
        }
        return false;
    }

    //@dev 关闭认购
    function close() onlyOperator() public {
        if (status == 0) {
            status = 1;
            Close(msg.sender, "关闭成功", true);
        } else {
            Close(msg.sender, "无法关闭认购，原因：认购尚未启动", false);
        }
    }

    //@dev 开奖
    function draw() onlyOperator() public {
        if (status == 1) {
            if (totalPurchased < total) {
                //认购人数不足，退回认购费用，退回资产
                /*uint len = accounts.keys.length;
                for (uint i = 0; i < len; i++) {
                    address to = accounts.keys[i];
                    UserAccount storage amt = accounts.map[to];
                    for (uint j = 0; j < amt.numbers.length; j++) {
                        UserNumbers storage n = amt.numbers[j];
                        cnyToken.transfer(to, n.cash);
                    }
                }
                uint b = ireToken.balanceOf(this);
                ireToken.transfer(assetOwner, b);*/
                Draw(msg.sender, "认购人数不足，项目终止", false);
            }
            else {
                if (generateWinnerNumbers()) {
                    status = 2;
                    Draw(msg.sender, "开奖成功", true);
                }
                else {
                    Draw(msg.sender, "开奖失败，原因：摇出号码错误", false);
                }
            }
        } else {
            Draw(msg.sender, "开奖失败，原因：认购未关闭", false);
        }
    }

    //@dev 根据中签结果计算每个认购者的份额
    function calculateShares() onlyOperator() public {
        if (status == 2) {
            for (uint i = 0; i < accounts.keys.length; i++) {
                UserAccount storage amt = accounts.map[accounts.keys[i]];
                for (uint j = 0; j < amt.numbers.length; j++) {
                    UserNumbers storage n = amt.numbers[j];
                    n.shares = findWinCount(n.min, n.max);
                    n.cashLeft = n.cash - (n.shares * unitPrice);
                }
            }
            status = 3;
            CalculateShares(msg.sender, "计算成功", true);
        } else {
            CalculateShares(msg.sender, "计算份额失败，原因：未开奖", false);
        }
    }

    //@dev 分配份额并退回剩余认购款
    function allocateShares() onlyOperator() public {
        if (status == 3) {
            for (uint i = 0; i < accounts.keys.length; i++) {
                address to = accounts.keys[i];
                allocateSharesOf(to);
            }
            uint balance = cnyToken.balanceOf(this);
            cnyToken.transfer(assetOwner, balance);
            status = 4;
            AllocateShares(msg.sender, "分配成功", true);
        } else {
            if (status < 4)
                AllocateShares(msg.sender, "未计算份额，先计算份额后才能分配", false);
            if (status == 4)
                AllocateShares(msg.sender, "已分配完毕", false);
        }
    }

    function allocateSharesOf(address user) onlyOperator() private {
        UserAccount storage amt = accounts.map[user];
        for (uint j = 0; j < amt.numbers.length; j++) {
            UserNumbers storage n = amt.numbers[j];
            if (n.shares > 0) {
                //份额换算, 隐含条件，认购时最小单位份额不能小于资产最小单位份额
                uint shares = n.shares * 10 ** (ireToken.decimals() - decimals);
                ireToken.transfer(user, shares);
            }
            if (n.cashLeft > 0)
                cnyToken.transfer(user, n.cashLeft);
        }
    }

    function finalize() onlyOperator() public {
        if (status < 4) {
            uint balance = ireToken.balanceOf(this);
            if (balance > 0)
                ireToken.transfer(assetOwner, balance);
            for (uint i = 0; i < accounts.keys.length; i++) {
                address to = accounts.keys[i];
                finalizeOf(to);
            }
            status = 5;
            Finalize(msg.sender, "中止成功", true);
        }
        else {
            Finalize(msg.sender, "中止失败，原因：项目已结束", false);
        }
    }

    function finalizeOf(address user) onlyOperator() private {
        if (status < 4) {
            uint balance = ireToken.balanceOf(this);
            if (balance > 0)
                ireToken.transfer(assetOwner, balance);
            if (accounts.map[user].flag) {
                for (uint j = 0; j < accounts.map[user].numbers.length; j++) {
                    UserNumbers storage n = accounts.map[user].numbers[j];
                    cnyToken.transfer(user, n.cash);
                }
                accounts.map[user].flag = false;
            }
        }
        else {
            Finalize(msg.sender, "中止失败，原因：项目已结束", false);
        }
    }

    //@dev 计算用户剩余可认购额度
    function getUserLeft() public view returns (uint){
        uint userTotal;
        UserAccount storage amt = accounts.map[msg.sender];
        for (uint i = 0; i < amt.numbers.length; i++) {
            UserNumbers storage u = amt.numbers[i];
            if (u.timeStamp > 0)
                userTotal += (u.max - u.min + 1);
        }
        return userLimit - userTotal;
    }

    function getAssetOwner() public view returns (address){
        return assetOwner;
    }

    function getDecimals() public view returns (uint){
        return decimals;
    }

    function getUnitPrice() public view returns (uint){
        return unitPrice;
    }

    function getUserLimits() public view returns (uint){
        return userLimit;
    }

    function getIreToken() public view returns (address){
        return ireToken;
    }

    function getCnyToken() public view returns (address){
        return cnyToken;
    }

    function getStatus() public view returns (int){
        return status;
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
    function sharesOf(address adr) public view returns (uint, uint){
        UserNumbers[] storage numbers = accounts.map[adr].numbers;
        uint shares;
        uint cashLeft;
        for (uint i = 0; i < numbers.length; i++) {
            UserNumbers storage n = numbers[i];
            shares += n.shares;
            cashLeft += n.cashLeft;
        }
        return (shares, cashLeft);
    }

    ///@dev 获取用户配号段和缴款信息
    function numbersOf(address adr) public view returns (uint[]){
        uint[] memory numbers = new uint[](accounts.map[adr].numbers.length * 2);
        uint j = 0;
        for (uint i = 0; i < accounts.map[adr].numbers.length; i++) {
            UserNumbers storage n = accounts.map[adr].numbers[i];
            numbers[j] = n.min;
            j++;
            numbers[j] = n.max;
            j++;
        }
        return numbers;
    }

    ///@dev 是否已转入资金
    function hasTransfer(address adr) public view returns (bool){
        return accounts.map[adr].flag;
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (token == address(ireToken)) {
            //未开启认购前才允许转入资产
            if (status >= 0)
                return 0;
            assetOwner = sender;
            return value;
        }
        else if (token == address(cnyToken)) {
            //只有开启认购状态才允许转入资金
            if (status != 0)
                return 0;
            UserAccount storage account = accounts.map[sender];
            if (!account.flag) {
                account.flag = true;
                accounts.keys.push(sender);
                account.numbers.push(UserNumbers(0, 0, value, 0, 0, 0));
            }
            else {
                bool flag = false;
                uint i = account.numbers.length - 1;
                if (account.numbers[i].timeStamp == 0) {
                    account.numbers[i].cash += value;
                    flag = true;
                }
                if (!flag) {
                    account.numbers.push(UserNumbers(0, 0, value, 0, 0, 0));
                }
            }
            return value;
        }
        else {
            return 0;
        }
    }

    /*********************************************************************************************************/
    /*******以下为摇号相关代码*******/


    function generateWinnerNumbers() private returns (bool) {
        uint hash = uint(keccak256(seedHash));
        //从末m位开始摇号
        uint e = findRoundExponent(total, 0);
        //摇号除数
        uint d = 10 ** e;
        uint counter = 0;
        while (counter < total) {
            //hash后求尾数，如果尾数未被抽出，记下尾号并从总号池中减掉尾号对应的号码数量
            hash = uint(keccak256(hash));
            uint winner = hash % d;
            bool flag = verify(winner);
            if (!flag) {
                storeNumber(e, winner);
                uint q = totalPurchased / d;
                uint r = totalPurchased % d;
                //被抽中的号数等于尾数匹配后的商加余数（不能整除且余数大于等于尾号的，抽中数需多加1）
                uint winnersCount = q + ((r > 0 && r >= winner) ? 1 : 0);
                counter += winnersCount;
                uint remaining = total - counter;
                //计算剩余号数，如果大于零计算下一轮的尾号位数并继续
                if (remaining > 0) {
                    uint exponent = findRoundExponent(remaining, e);
                    if (exponent != e) {
                        e = exponent;
                        d = 10 ** exponent;
                    }
                    //如果下一轮尾号数大于了总号数，进入逐一抽取程序后退出，否则更新尾号后继续
                    if (d > totalPurchased) {
                        findLuckyNumbers(remaining, hash, e);
                        counter += remaining;
                        break;
                    }
                }
            }
        }
        if (counter != total) {
            return false;
        }
        return true;
    }

    //@dev 记录摇到的尾号
    //@param exponent 尾号位数
    //@param luckyNumber 尾号数值
    function storeNumber(uint exponent, uint luckyNumber) private {
        Winners storage numbers = winners.map[exponent];
        if (!numbers.flag) {
            winners.keys.push(exponent);
            numbers.flag = true;
        }
        numbers.numbers.push(luckyNumber);
    }


    //@dev 给定一最大配号，返回所中数量
    //@param max 最大配号
    function findWinCount(uint max) public view returns (uint){
        require(max > 0);
        uint sum;
        for (uint i = 0; i < winners.keys.length; i++) {
            uint e = winners.keys[i];
            uint[] memory numbers = winners.map[e].numbers;
            uint d = 10 ** e;
            for (uint j = 0; j < numbers.length; j++) {
                uint number = numbers[j];
                uint q = max / d;
                uint r = max % d;
                uint a = (r > 0 && r >= number) ? 1 : 0;
                sum += (q + a);
            }
        }
        return sum;
    }

    //@dev 给定一号段，返回所中数量
    //@param min 最小配号
    //@param max 最大配号
    function findWinCount(uint min, uint max) public view returns (uint){
        require(max >= min);
        require(min > 0);
        if (min <= 1)
            return findWinCount(max);
        return findWinCount(max) - findWinCount(min - 1);
    }


    //@dev 逐个摇出中奖号
    //@param totalRemaining 剩余总号数
    //@param randomNumber 随机数
    //@param exponent 尾号位数
    function findLuckyNumbers(uint totalRemaining, uint randomNumber, uint exponent) private {
        uint counter = 0;
        uint hash = randomNumber;
        while (counter < totalRemaining) {
            hash = uint(keccak256(hash));
            //整除情况下余数为0，而号码段起始数为1，所以整体号码对应关系需要加1
            uint q = (hash % totalPurchased) + 1;
            bool isExist = verify(q);
            if (!isExist) {
                storeNumber(exponent, q);
                counter++;
            }
        }
    }

    //@dev 根据总号数和排号数量计算出第一轮摇号需要的尾号位数个数
    //@param totalRemaining 剩余总号数
    //@param exponent 起始尾号位数
    function findRoundExponent(uint totalRemaining, uint exponent) private view returns (uint){
        //确保选中尾号后满足条件的排号小于总号数
        uint e = exponent;
        uint d = 10 ** e;
        while ((totalPurchased / d) + (totalPurchased % d > 0 ? 1 : 0) > totalRemaining) {
            e++;
            d = 10 ** e;
        }
        return e;
    }

    //@dev 检查所中尾号段是否与已有的重复
    //@param lucky 尾号数
    function verify(uint lucky) private view returns (bool){
        //遍历所有已摇出的尾号进行匹配，如果有重复，本次摇号无效
        //如：已摇出尾号5，86，353，8723，则再次摇号四位数诸如2135，3386，4353，8723均为无效号码
        //数学上判断方法为两数求差，除以对应的尾号十进制位数幂级余数为0
        bool flag = false;
        for (uint i = 0; i < winners.keys.length; i++) {
            uint e = winners.keys[i];
            uint[] storage arrLucky = winners.map[e].numbers;
            uint d = 10 ** e;
            for (uint j = 0; j < arrLucky.length; j++) {
                uint l = arrLucky[j];
                uint t = lucky > l ? lucky - l : l - lucky;
                if (t % d == 0) {
                    flag = true;
                    break;
                }
            }
        }
        return flag;
    }

    function getExponents() public view returns (uint){
        uint bits = 0;
        for (uint i = winners.keys.length; i >= 1; i--) {
            bits = (bits * 10 + winners.keys[i - 1]);
        }
        return bits;
    }

    function getLuckyNumbers(uint key) public view returns (uint){
        return winners.map[key].numbers.length;
    }

    function getLuckyNumbersOfExponent(uint key, uint index) public view returns (uint){
        return winners.map[key].numbers[index];
    }

    function getWinnerKeys() public view returns (uint[]){
        return winners.keys;
    }

    function getWinnerNumbers(uint key) public view returns (uint[]){
        return winners.map[key].numbers;
    }

    function getDrawResult() public view returns (uint[]){
        uint size = 0;
        for (uint i = 0; i < winners.keys.length; i++) {
            uint len = winners.map[winners.keys[i]].numbers.length;
            size += len;
        }
        uint[] memory n = new uint[](size);
        uint f = 0;
        for (uint j = 0; j < winners.keys.length; j++) {
            uint[] storage numbers = winners.map[winners.keys[j]].numbers;
            for (uint k = 0; k < numbers.length; k++) {
                n[f] = numbers[k];
                f++;
            }
        }
        return n;
    }
}
