pragma solidity ^0.4.0;

import '../contracts/ERC721Council.sol';
import "../contracts/ERC721.sol";
import "../contracts/ERC721Project.sol";
import "../contracts/NamingController.sol";
//@title资产委员会
contract IRECouncil is ERC721Council {
    struct Token {
        bool flag;
        uint keyIndex;
    }

    struct AddressToken {
        bool flag;
        uint[] keys;
        mapping(uint => Token) map;
    }

    struct AddressTokens {
        address[] keys;
        mapping(address => AddressToken) map;
    }

    struct Commission {
        address[] keys;
        mapping(address => Comm) map;
    }

    struct Comm {
        bool flag;
        uint keyIndex;
        address[] keys;
        mapping(address => Member) map;
    }

    struct Member {
        bool flag;
        uint keyIndex;
    }

    struct State {
        address from;
        address to;
        uint index;
    }

    struct CurrentState {
        State state;
        address member;
        bool abandonFlag;
    }

    struct TokenTemp {
        bytes tempNum;
        address[] states;
    }

    NamingController nc;
    mapping(uint => State[]) tokenToStates;
    mapping(uint => CurrentState) tokenToState;
    mapping(uint => AddressTokens) addressToTokens;
    uint[] tokens;
    Commission commission;

    function IRECouncil(NamingController _nc) public {
        nc = _nc;
    }

    function naming() public view returns (address){
        return nc;
    }

    function getERC721() private returns (ERC721){
        return ERC721(nc.getContract("ERC721", 0));
    }

    function init(uint tokenId, uint commissions) onlyOperator external {
        ERC721 asset = getERC721();
        address owner = asset.ownerOf(tokenId);
        if (owner == address(this)) {
            uint count = 1;
            while (count < 10) {
                if (commissions / (10 ** count) == 0) {
                    break;
                }
                count++;
            }
            uint max = count;
            while (max > 0) {
                uint i = max - 1;
                uint d = commissions / (10 ** i);
                uint idx = d % 10;
                address state = commission.keys[idx];
                uint flag = count - 1 - i;
                tokenToStates[tokenId].push(State(state, state, flag));
                if (flag > 0) {
                    tokenToStates[tokenId][flag - 1].to = state;
                }
                max--;
            }
            Init(msg.sender, tokenId, 0);
        } else {
            Init(msg.sender, tokenId, 1);
        }
    }

    function abandon(uint tokenId) onlyOperator external {
        ERC721 asset = getERC721();
        address owner = asset.ownerOf(tokenId);
        if (owner == address(this)) {
            tokenToState[tokenId].abandonFlag = true;
            Abandon(msg.sender, tokenId, 0);
        } else {
            Abandon(msg.sender, tokenId, 1);
        }
    }

    function update(uint key, address adr, uint tokenId) private {
        if (!addressToTokens[key].map[adr].flag) {
            addressToTokens[key].keys.push(adr);
            addressToTokens[key].map[adr].flag = true;
        }
        AddressToken storage at = addressToTokens[key].map[adr];
        if (!at.map[tokenId].flag) {
            at.map[tokenId].keyIndex = at.keys.length;
            at.keys.push(tokenId);
            at.map[tokenId].flag = true;
        }
    }

    function remove(uint key, address adr, uint tokenId) private {
        if (addressToTokens[key].map[adr].flag) {
            AddressToken storage at = addressToTokens[key].map[adr];
            if (at.map[tokenId].flag) {
                at.map[tokenId].flag = false;
                uint keyIndex = at.map[tokenId].keyIndex;
                if (keyIndex != at.keys.length - 1) {
                    for (uint i = keyIndex + 1; i < at.keys.length; i++) {
                        uint v = at.keys[i];
                        at.keys[i - 1] = v;
                        at.map[v].keyIndex = i - 1;
                    }
                }
                at.map[tokenId].keyIndex = 0;
                at.keys.length -= 1;
            }
        }
    }

    function transit(address adr1, address adr2, address adr3, uint tokenId) private {
        remove(0, adr1, tokenId);
        update(0, adr2, tokenId);
        remove(1, adr2, tokenId);
        update(1, adr3, tokenId);
    }

    function next(uint tokenId) external {
        ERC721Project project = ERC721Project(nc.getContract("ERC721Project", tokenId));
        ERC721 asset = getERC721();
        address owner = asset.ownerOf(tokenId);
        if (owner == address(this)) {
            address liquidationCmt = liquidationCommission();
            if (tokenToState[tokenId].abandonFlag) {
                //如果是废弃的项目，不允许触发next
                Next(msg.sender, address(0), address(0), tokenId, 2);
            }
            else {
                address from = tokenToState[tokenId].state.from;
                address to = tokenToState[tokenId].state.to;
                uint index = tokenToState[tokenId].state.index;
                if (from != address(0)) {
                    if (from != liquidationCmt) {
                        if (index == tokenToStates[tokenId].length - 1) {
                            if (project.commissionChanging(from, to, msg.sender)) {
                                project.commissionChanged(from, to, msg.sender);
                            }
                        } else {
                            State storage ns = tokenToStates[tokenId][index + 1];
                            if (project.commissionChanging(from, to, msg.sender)) {
                                tokenToState[tokenId].state = ns;
                                transit(from, to, ns.to, tokenId);
                                project.commissionChanged(from, to, msg.sender);
                            }
                        }
                        Next(msg.sender, from, to, tokenId, 0);
                    }
                } else {
                    tokens.push(tokenId);
                    State storage o = tokenToStates[tokenId][0];
                    if (project.commissionChanging(address(0), o.from, msg.sender)) {
                        tokenToState[tokenId].state = o;
                        transit(address(0), o.from, o.to, tokenId);
                        project.commissionChanged(address(0), o.from, msg.sender);
                    }
                    Next(msg.sender, address(0), o.from, tokenId, 0);
                }
            }
        }
        else {
            Next(msg.sender, address(0), address(0), tokenId, 1);
        }
    }

    function liquidate(uint tokenId) external {
        address from = tokenToState[tokenId].state.from;
        ERC721 asset = getERC721();
        address owner = asset.ownerOf(tokenId);
        ERC721Project project = ERC721Project(nc.getContract("ERC721Project", tokenId));
        address liquidationCmt = liquidationCommission();
        if (owner == address(this)) {
            if (project.commissionChanging(from, liquidationCmt, msg.sender)) {
                tokenToState[tokenId].state = State(liquidationCmt, liquidationCmt, 0);
                transit(from, liquidationCmt, liquidationCmt, tokenId);
                project.commissionChanged(from, liquidationCmt, msg.sender);
                project.liquidate();
            }
        }
    }

    //@dev 所属机构认领资产
    //@param tokenId 资产的Id
    function take(uint tokenId) external {
        ERC721 asset = getERC721();
        address owner = asset.ownerOf(tokenId);
        //判断token当前拥有者
        //如果拥有者不是该委员会，那么或者是下属机构已认领或者是流程已进入其他委员会
        if (owner == address(this)) {
            if (tokenToState[tokenId].abandonFlag) {
                Take(msg.sender, tokenId, 3);
            }
            else {
                address comm = tokenToState[tokenId].state.to;
                address m = tokenToState[tokenId].member;
                if (m == address(0)) {
                    if (isMemberOf(comm, msg.sender)) {
                        tokenToState[tokenId].member = msg.sender;
                        update(2, msg.sender, tokenId);
                        Take(msg.sender, tokenId, 0);
                    } else {
                        Take(msg.sender, tokenId, 1);
                    }
                } else {
                    Take(msg.sender, tokenId, 2);
                }
            }
        } else {
            Take(msg.sender, tokenId, 3);
        }
    }

    //@dev 释放资产所有权到所属委员会
    //@param committee 委员会
    //@param tokenId 资产Id
    function release(uint tokenId) external {
        //需满足如下条件：
        //1.token的当前拥有者是当前委员会
        //2.负责机构为当前调用方
        ERC721 asset = getERC721();
        address owner = asset.ownerOf(tokenId);
        if (owner == address(this)) {
            address m = tokenToState[tokenId].member;
            if (m == msg.sender) {
                tokenToState[tokenId].member = address(0);
                remove(2, m, tokenId);
                Release(msg.sender, tokenId, 0);
            } else {
                Release(msg.sender, tokenId, 1);
            }
        } else {
            Release(msg.sender, tokenId, 2);
        }
    }

    function add(address com) onlyOperator external {
        if (!commission.map[com].flag) {
            commission.map[com].keyIndex = commission.keys.length;
            commission.keys.push(com);
            commission.map[com].flag = true;
            Add(msg.sender, com, 0);
        } else {
            Add(msg.sender, com, 1);
        }
    }

    function insert(uint index, address com) onlyOperator external {
        if (!commission.map[com].flag) {
            if (index > commission.keys.length) {
                Insert(msg.sender, com, index, 1);
            } else {
                commission.map[com].keyIndex = commission.keys.length;
                commission.keys.push(com);
                commission.map[com].flag = true;
                for (uint i = commission.keys.length - 2; i >= index; i--) {
                    address comm = commission.keys[i];
                    commission.keys[i] = com;
                    commission.keys[i + 1] = comm;
                    commission.map[comm].keyIndex = i + 1;
                }
                Insert(msg.sender, com, index, 0);
            }
        } else {
            Insert(msg.sender, com, index, 2);
        }
    }

    function remove(address com) onlyOperator external {
        if (commission.map[com].flag) {
            if (tokensOf(com).length > 0 || tokensOfNextCommission(com).length > 0) {
                Remove(msg.sender, com, 1);
            }
            else {
                commission.map[com].flag = false;
                uint keyIndex = commission.map[com].keyIndex;
                if (keyIndex != commission.keys.length - 1) {
                    for (uint i = keyIndex + 1; i < commission.keys.length; i++) {
                        address v = commission.keys[i];
                        commission.keys[i - 1] = v;
                        commission.map[v].keyIndex = i - 1;
                    }
                }
                commission.map[com].keyIndex = 0;
                commission.keys.length -= 1;
                Remove(msg.sender, com, 0);
            }
        } else {
            Remove(msg.sender, com, 2);
        }
    }

    //@dev添加委员会成员
    //@param member 成员账户地址
    function addMember(address member) external {
        //用户必须是委员会才有权限添加所辖机构
        if (!commission.map[msg.sender].flag) {
            AddMember(msg.sender, member, 1);
        }
        else {
            Comm storage comm = commission.map[msg.sender];
            if (!comm.map[member].flag) {
                comm.map[member].keyIndex = comm.keys.length;
                comm.keys.push(member);
                comm.map[member].flag = true;
                AddMember(msg.sender, member, 0);
            } else {
                AddMember(msg.sender, member, 2);
            }
        }
    }

    //@dev删除委员会成员
    //@param member 成员账户地址
    function removeMember(address member) external {
        //检查委员会成员是否还有资产。有则不允许删除
        //否则删除成员并重新设置成员数组大小和索引
        if (tokensOfMember(member).length > 0) {
            RemoveMember(msg.sender, member, 1);
        }
        else {
            //移除成员后，索引在成员后的成员索引全部减少1
            Comm storage comm = commission.map[msg.sender];
            if (comm.map[member].flag) {
                comm.map[member].flag = false;
                uint keyIndex = comm.map[member].keyIndex;
                if (keyIndex < comm.keys.length) {
                    for (uint i = keyIndex + 1; i < comm.keys.length; i++) {
                        address v = comm.keys[i];
                        comm.keys[i - 1] = v;
                        comm.map[v].keyIndex = i - 1;
                    }
                }
                comm.map[member].keyIndex = 0;
                comm.keys.length -= 1;
            }
            RemoveMember(msg.sender, member, 0);
        }
    }

    function liquidationCommission() public view returns (address){
        return commission.keys[0];
    }

    function commissions() public view returns (address[]){
        return commission.keys;
    }

    function commissionCount() public view returns (uint){
        return commission.keys.length;
    }

    function commissionAt(uint index) public view returns (address){
        return commission.keys[index];
    }

    //@dev 委员会数量
    function commissionCountOf(uint tokenId) external view returns (uint){
        return tokenToStates[tokenId].length;
    }

    //@dev 委员会
    function commissionAtOf(uint tokenId, uint index) external view returns (address){
        return tokenToStates[tokenId][index].from;
    }

    function commissionsOf(uint tokenId) external view returns (address[]){
        uint len = tokenToStates[tokenId].length;
        address[] memory states = new address[](len);
        for (uint i = 0; i < tokenToStates[tokenId].length; i++) {
            states[i] = tokenToStates[tokenId][i].from;
        }
        return states;
    }

    function commissionOf(uint tokenId) external view returns (address) {
        return tokenToState[tokenId].state.from;
    }

    function isAbandoned(uint tokenId) external view returns (bool){
        return tokenToState[tokenId].abandonFlag;
    }

    function nextCommissionOf(uint tokenId) external view returns (address) {
        return tokenToState[tokenId].state.to;
    }

    function memberOf(uint tokenId) external view returns (address){
        return tokenToState[tokenId].member;
    }

    function commissionsOfMember(address member) external view returns (address[]){
        uint len;
        for (uint i = 0; i < commission.keys.length; i++) {
            address comm = commission.keys[i];
            if (isMemberOf(comm, member)) {
                len++;
            }
        }
        address[] memory committeesOfMember = new address[](len);
        uint k = 0;
        for (uint j = 0; j < commission.keys.length; j++) {
            if (isMemberOf(commission.keys[j], member)) {
                committeesOfMember[k] = commission.keys[j];
                k++;
            }
        }
        return committeesOfMember;
    }

    //@dev判断某机构是不是该委员会成员
    //@param adr 机构账户地址
    function isMemberOf(address committee, address member) public view returns (bool){
        return commission.map[committee].map[member].flag;
    }

    //@dev获取委员会所有机构账户地址
    function membersOf(address committee) external view returns (address[]){
        return commission.map[committee].keys;
    }

    function memberCountOf(address committee) public view returns (uint){
        return commission.map[committee].keys.length;
    }

    function tokensOf(address committee) public view returns (uint[]){
        return addressToTokens[0].map[committee].keys;
    }

    function tokenCountOf(address committee) public view returns (uint){
        return addressToTokens[0].map[committee].keys.length;
    }

    function tokensOfNextCommission(address committee) public view returns (uint[]){
        return addressToTokens[1].map[committee].keys;
    }

    function tokenCountOfNextCommission(address committee) public view returns (uint){
        return addressToTokens[1].map[committee].keys.length;
    }

    function tokensOfMember(address member) public view returns (uint[]){
        return addressToTokens[2].map[member].keys;
    }

    function tokenCountOfMember(address member) public view returns (uint){
        return addressToTokens[2].map[member].keys.length;
    }
}
