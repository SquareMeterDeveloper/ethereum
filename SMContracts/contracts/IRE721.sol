pragma solidity ^0.4.0;

import '../contracts/ERC721.sol';

contract IRE721 is ERC721 {
    struct AssetToken {
        uint id;
    }

    mapping(address => uint) balances;
    mapping(uint => address) tokenToOwner;
    mapping(uint => address) tokenToApproved;
    uint[] tokenIds;
    event Create(address indexed from, uint indexed tokenId, uint code);

    //@dev 创建资产
    //@param tokeId 资产Id
    //@param symbol 资产名称
    function create(uint tokenId) onlyOperator() external returns (bool) {
        if (tokenToOwner[tokenId] != address(0)) {
            Create(msg.sender, tokenId, 1);
            return false;
        }
        else {
            tokenIds.push(tokenId);
            address owner = msg.sender;
            tokenToOwner[tokenId] = owner;
            balances[owner]++;
            Create(msg.sender, tokenId, 0);
            return true;
        }
    }

    //@dev 资产所有权转移
    //@param to 转入账户地址
    //@param tokenId 资产Id
    function transfer(address to, uint tokenId) external {
        address owner = tokenToOwner[tokenId];
        if (owner == address(0)) {
            Transfer(msg.sender, msg.sender, to, tokenId, 1);
        }
        else if (owner != msg.sender) {
            Transfer(msg.sender, msg.sender, to, tokenId, 2);
        } else {
            tokenToOwner[tokenId] = to;
            tokenToApproved[tokenId] = address(0);
            balances[owner]--;
            balances[to]++;
            Transfer(msg.sender, msg.sender, to, tokenId, 0);
        }
    }

    //@dev 资产所有权转移
    //@param from 转出账户地址
    //@param to 转入账户地址
    //@param tokenId 资产Id
    function transferFrom(address from, address to, uint tokenId) external {
        address owner = tokenToOwner[tokenId];
        if (owner == address(0)) {
            Transfer(msg.sender, owner, to, tokenId, 1);
        }
        else if (owner == from && tokenToApproved[tokenId] == msg.sender) {
            tokenToOwner[tokenId] = to;
            tokenToApproved[tokenId] = address(0);
            balances[owner]--;
            balances[to]++;
            Transfer(msg.sender, owner, to, tokenId, 0);
        } else {
            Transfer(msg.sender, owner, to, tokenId, 2);
        }
    }

    //@dev 授权用户某token的转移权
    //@param to 被授权账户地址
    //@param tokenId Id
    function approve(address to, uint tokenId) external {
        address owner = tokenToOwner[tokenId];
        if (owner == address(0)) {
            Approve(msg.sender, to, tokenId, 1);
        }
        else if (owner != msg.sender) {
            Approve(msg.sender, to, tokenId, 2);
        } else {
            tokenToOwner[tokenId] = to;
            Approve(msg.sender, to, tokenId, 0);
        }
    }

    function totalSupply() public view returns (uint){
        return tokenIds.length;
    }

    function balanceOf(address owner) public view returns (uint){
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address){
        return tokenToOwner[tokenId];
    }

    function tokens() external view returns (uint[]){
        return tokenIds;
    }
}
