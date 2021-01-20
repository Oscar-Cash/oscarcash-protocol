pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IDistributor.sol';
import '../interfaces/IRewardDistributionRecipient.sol';

contract InitialShareDistributor is IDistributor {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 cashAmount);

    bool public once = true;

    IERC20 public share;
    IRewardDistributionRecipient public daioscLPPool;
    uint256 public daioscInitialBalance;
    IRewardDistributionRecipient public daiossLPPool;
    uint256 public daiossInitialBalance;

    constructor(
        IERC20 _share,
        IRewardDistributionRecipient _daioscLPPool,
        uint256 _daioscInitialBalance,
        IRewardDistributionRecipient _daiossLPPool,
        uint256 _daiossInitialBalance
    ) public {
        share = _share;
        daioscLPPool = _daioscLPPool;
        daioscInitialBalance = _daioscInitialBalance;
        daiossLPPool = _daiossLPPool;
        daiossInitialBalance = _daiossInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialShareDistributor: you cannot run this function twice'
        );

        share.transfer(address(daioscLPPool), daioscInitialBalance);
        daioscLPPool.notifyRewardAmount(daioscInitialBalance);
        emit Distributed(address(daioscLPPool), daioscInitialBalance);

        share.transfer(address(daiossLPPool), daiossInitialBalance);
        daiossLPPool.notifyRewardAmount(daiossInitialBalance);
        emit Distributed(address(daiossLPPool), daiossInitialBalance);

        once = false;
    }
}
