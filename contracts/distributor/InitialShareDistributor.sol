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
    IRewardDistributionRecipient public usdtoscLPPool;
    uint256 public usdtoscInitialBalance;
    IRewardDistributionRecipient public usdtossLPPool;
    uint256 public usdtossInitialBalance;
    IRewardDistributionRecipient public osbossPool;
    uint256 public osbossInitialBalance;

    constructor(
        IERC20 _share,
        IRewardDistributionRecipient _usdtoscLPPool,
        uint256 _usdtoscInitialBalance,
        IRewardDistributionRecipient _usdtossLPPool,
        uint256 _usdtossInitialBalance,
        IRewardDistributionRecipient _osbossPool,
        uint256 _osbossInitialBalance
    ) public {
        share = _share;
        usdtoscLPPool = _usdtoscLPPool;
        usdtoscInitialBalance = _usdtoscInitialBalance;
        usdtossLPPool = _usdtossLPPool;
        usdtossInitialBalance = _usdtossInitialBalance;
        osbossPool =  _osbossPool;
        osbossInitialBalance = _osbossInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialShareDistributor: you cannot run this function twice'
        );

        share.transfer(address(usdtoscLPPool), usdtoscInitialBalance);
        usdtoscLPPool.notifyRewardAmount(usdtoscInitialBalance);
        emit Distributed(address(usdtoscLPPool), usdtoscInitialBalance);

        share.transfer(address(usdtossLPPool), usdtossInitialBalance);
        usdtossLPPool.notifyRewardAmount(usdtossInitialBalance);
        emit Distributed(address(usdtossLPPool), usdtossInitialBalance);

        share.transfer(address(osbossPool), osbossInitialBalance);
        osbossPool.notifyRewardAmount(osbossInitialBalance);
        emit Distributed(address(osbossPool), osbossInitialBalance);

        once = false;
    }
}
