pragma solidity ^0.6.0;

import './owner/Operator.sol';

contract Referral is Operator {
    mapping(address => address) public referrers; 
    mapping(address => uint256) public referredCount; 

    mapping(address => bool) public isAdmin;

    event BindReferral(
        address indexed referrer, 
        address indexed participant
    );
    
    modifier onlyAdmin {
        require(isAdmin[msg.sender], "Oscar Referral: OnlyAdmin methods called by non-admin.");
        _;
    }

    function setReferrer(address participant, address referrer) public onlyAdmin {
        if (referrers[participant] == address(0) && referrer != address(0)) {
             if(referrers[participant] != address(0)){
                referredCount[referrers[participant]] = referredCount[referrers[msg.sender]] -1;
            }
            referrers[participant] = referrer;
            referredCount[referrer] += 1;
            emit BindReferral(referrer, participant);
        }
    }

    function setSelfReferrer(address referrer) public {
        if ( referrer != address(0)) {
            if(referrers[msg.sender] != address(0)){
                referredCount[referrers[msg.sender]] = referredCount[referrers[msg.sender]] -1;
            }
            referrers[msg.sender] = referrer;
            referredCount[referrer] += 1;
            emit BindReferral(referrer, msg.sender);
        }
    }

    function getReferrer(address farmer) public view returns (address) {
        return referrers[farmer];
    }

    function setAdminStatus(address _admin, bool _status) external onlyOperator{
        isAdmin[_admin] = _status;
    }
}