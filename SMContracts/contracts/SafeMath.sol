pragma solidity ^0.4.0;

contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z, bool success) {
        if (x > MAX_UINT256 - y)
            return (0, false);
        return (x + y, true);
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z, bool success) {
        if (x < y)
            return (0, false);
        return (x - y, true);
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z, bool success) {
        if (y == 0)
            return (0, false);
        if (x > MAX_UINT256 / y)
            return (0, false);
        return (x * y, true);
    }
}
