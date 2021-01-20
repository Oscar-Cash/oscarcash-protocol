pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFreeFromUpTo is IERC20{
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}