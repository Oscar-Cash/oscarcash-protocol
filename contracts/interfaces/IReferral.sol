pragma solidity ^0.6.0;

interface IReferral {
    function setReferrer(address participant, address referrer) external;
    function getReferrer(address participant) external view returns (address);
}