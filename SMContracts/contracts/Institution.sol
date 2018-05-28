pragma solidity ^0.4.0;

import "./IRECouncil.sol";

contract CommitteeMember {

    bool inCharge = false;
    IRECouncil committee;

    function CommitteeMember(IRECouncil _committee) public {
        committee = _committee;
    }

    function isInCharge() public view returns (bool) {
        return inCharge;
    }

    function getCommittee() public view returns (IRECouncil){
        return committee;
    }
}
