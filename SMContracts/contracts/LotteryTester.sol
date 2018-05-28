pragma solidity ^0.4.0;

import "../contracts/Lottery.sol";
import "../contracts/ERC20.sol";

contract LotteryTester is ContractReceiver {
    uint[] exponents;
    mapping(uint => uint[]) map;

    function purchase(ERC20 cnyToken, Lottery lottery, uint timeStamp, uint amount, uint unitPrice) public {
        cnyToken.transfer(lottery, amount * unitPrice);
        lottery.purchase(timeStamp, amount);
    }

    function initialize(Lottery lottery) public {
        uint length = lottery.getExponents();
        while (length > 0) {
            uint e = length % 10;
            exponents.push(e);
            uint count = lottery.getLuckyNumbers(e);
            for (uint j = 0; j < count; j++) {
                uint number = lottery.getLuckyNumbersOfExponent(e, j);
                map[e].push(number);
            }
            length = length / 10;
        }
    }

    function validateNumbers() public view returns (bool){
        for (uint i = 0; i < exponents.length; i++) {
            uint e = exponents[i];
            uint q = 10 ** e;
            uint[] memory numbers = map[e];
            for (uint j = 0; j < numbers.length; j++) {
                uint n = numbers[j];
                for (uint k = 0; k < exponents.length; k++) {
                    uint e2 = exponents[k];
                    if (e2 >= e) {
                        uint[] memory numbers2 = map[e2];
                        for (uint l = 0; l < numbers2.length; l++) {
                            if (e2 == e && l >= j)
                                break;
                            uint n2 = numbers2[l];
                            uint d = n2 > n ? n2 - n : n - n2;
                            if (d % q == 0)
                                return false;
                        }
                    }
                    else {
                        break;
                    }
                }
            }
        }
        return true;
    }

    function validateTotal(uint total, uint from) public view returns (bool){
        uint sum = 0;
        for (uint i = 0; i < exponents.length; i++) {
            uint e = exponents[i];
            uint q = 10 ** e;
            uint[] memory numbers = map[e];
            for (uint j = 0; j < numbers.length; j++) {
                uint n = numbers[j];
                uint d = from / q;
                uint r = from % q;
                uint m = (r > 0 && r >= n) ? 1 : 0;
                sum += (d + m);
            }
        }
        return total == sum;
    }

    function tokenFallback(address sender, uint value, address token) public returns (uint){
        if (sender != address(0) && token != address(0))
            return value;
        return 0;
    }
}
