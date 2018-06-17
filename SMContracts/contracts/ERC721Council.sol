pragma solidity ^0.4.0;

import '../contracts/Owned.sol';

contract ERC721Council is Owned {
    event Take(address indexed from, uint indexed tokenId, uint code);
    event Release(address indexed from, uint tokenId, uint code);
    event Next(address indexed from, address commissionFrom, address commissionTo, uint indexed tokenId, uint code);
    event Init(address indexed from, uint indexed tokenId, uint code);
    event Abandon(address indexed from, uint indexed tokenId, uint code);
    event Add(address indexed from, address indexed commission, uint code);
    event Insert(address indexed from, address indexed commission, uint index, uint code);
    event Remove(address indexed from, address indexed commission, uint code);
    event AddMember(address indexed from, address indexed member, uint code);
    event RemoveMember(address indexed from, address indexed member, uint code);
    //@dev 初始化token的委员会流转
    //@param tokenId 资产Id
    //@param commissions 委员会流转顺序
    function init(uint tokenId, uint commissions) onlyOperator external;

    //@dev 资产流转进入下一个委员会
    //@param tokenId 资产的Id
    function next(uint tokenId) external;

    //@dev 清算资产
    //@param tokenId 资产Id
    function liquidate(uint tokenId) external;

    //@dev 机构认领资产
    //@param tokenId 资产的Id
    function take(uint tokenId) external;

    //@dev 返回资产
    //@param tokenId 资产Id
    function release(uint tokenId) external;

    function add(address commission) onlyOperator external;

    function insert(uint index, address commission) onlyOperator external;

    function remove(address commission) onlyOperator external;

    function abandon(uint tokenId) onlyOperator external;

    //@dev 资产清算委员会
    function liquidationCommission() public view returns (address);

    //@dev 获取所有Token
    function getTokens() public view returns (uint[]);

    //@dev 所有委员会
    function commissions() public view returns (address[]);

    //@dev 委员会数量
    function commissionCount() public view returns (uint);

    //@dev 委员会
    function commissionAt(uint index) public view returns (address);

    //@dev token所设置的委员会流转顺序
    function commissionsOf(uint tokenId) external view returns (address[]);

    //@dev 委员会数量
    function commissionCountOf(uint tokenId) external view returns (uint);

    //@dev 委员会
    function commissionAtOf(uint index, uint tokenId) external view returns (address);

    //@dev 是否是委员会成员
    //@param commission 委员会
    //@param member 委员会成员
    function isMemberOf(address commission, address member) public view returns (bool);

    //@dev 获取委员会成员
    //@param commission 委员会
    function membersOf(address commission) external view returns (address[]);

    //@dev 获取成员所属委员会
    //@param member 委员会成员
    function commissionsOfMember(address member) external view returns (address[]);

    //@dev 资产所属委员会
    //@param tokenId 资产Id
    function commissionOf(uint tokenId) external view returns (address);

    //@dev 判断项目是否废弃
    //@param tokenId 资产Id
    function isAbandoned(uint tokenId) external view returns (bool);

    //@dev 资产所属委员会成员
    //@param tokenId 资产Id
    function memberOf(uint tokenId) external view returns (address);

    //@dev 委员会所管理资产
    //@param committee 委员会
    function tokensOf(address committee) public view returns (uint[]);

    //@dev 下一级委员会所能操作的资产
    //@param committee 委员会
    function tokensOfNextCommission(address committee) public view returns (uint[]);

    //@dev 委员会成员所管理资产
    //@param member 成员
    function tokensOfMember(address member) public view returns (uint[]);
}
