pragma solidity ^0.6.0;

interface IGasSponsor {
    function makeGasDiscount( uint256 gasSpent, bytes calldata msgSenderCalldata) external;
}