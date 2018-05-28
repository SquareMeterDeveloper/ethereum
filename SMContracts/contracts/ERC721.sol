pragma solidity ^0.4.0;

import '../contracts/Owned.sol';
//@title ERC721
contract ERC721 is Owned {
    // Required methods
    function totalSupply() public view returns (uint total);

    function balanceOf(address _owner) public view returns (uint balance);

    function ownerOf(uint _tokenId) external view returns (address owner);

    function tokens() external view returns (uint[] _tokens);

    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint _tokenId) external;

    function transferFrom(address from, address to, uint _tokenId) external;
    // Events
    event Transfer(address indexed from, address indexed owner, address indexed to, uint tokenId, uint code);
    event Approve(address indexed from, address indexed to, uint tokenId, uint code);
}
