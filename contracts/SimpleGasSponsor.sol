pragma solidity ^0.6.0;

import './interfaces/IGasDiscount.sol';
import './interfaces/IFreeFromUpTo.sol';
import './owner/Operator.sol';

contract SimpleGasSponsor is IGasSponsor, Operator {

    IFreeFromUpTo constant public chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    function makeGasDiscount(uint256 gasSpent, bytes calldata) external override onlyOperator{
            // msgSenderCalldata;
            if(chi.balanceOf(address(this)) >0) {
                chi.freeFromUpTo(address(this), (gasSpent + 14154) / 41130);
            }
    }

}