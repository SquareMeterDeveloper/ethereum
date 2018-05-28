pragma solidity ^0.4.0;

contract ERC721Receiver {
    function tokenFallback(address sender, uint tokenId) public returns (bool);
}
