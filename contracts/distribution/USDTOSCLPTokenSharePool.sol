pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../interfaces/IRewardDistributionRecipient.sol';
import '../interfaces/IReferral.sol';

import '../token/LPTokenWrapper.sol';

contract USDTOSCLPTokenSharePool is
    LPTokenWrapper,
    IRewardDistributionRecipient
{
    IERC20 public oscarShare;
    uint256 public constant DURATION = 30 days;
    uint256 public constant REFERRAL_REBATE_PERCENT = 1;
    uint256 public constant RISK_FUND_PERCENT = 3;
    uint256 public constant DEV_FUND_PERCENT = 2;

    uint256 public initreward = 86250 * 10**18; // 184,799.95 Shares
    uint256 public starttime; // starttime TBD
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    address public riskFundAddress;
    address public devFundAddress;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RiskFundRewardPaid(address indexed user, uint256 reward);
    event DevFundRewardPaid(address indexed user, uint256 reward);
    event ReferralRewardPaid(address indexed user, address indexed referral, uint256 reward);

    constructor(
        address oscarShare_,
        address lptoken_,
        address riskFundAddress_,
        address devFundAddress_,
        uint256 starttime_
    ) public {
        oscarShare = IERC20(oscarShare_);
        lpt = IERC20(lptoken_);
        riskFundAddress = riskFundAddress_;
        devFundAddress = devFundAddress_;
        starttime = starttime_;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stakeWithReferrer(uint256 amount, address referrer) external {
        stake(amount);
        if (rewardReferral != address(0) && referrer != address(0)) {
            IReferral(rewardReferral).setReferrer(msg.sender, referrer);
        }
    }

    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkhalve
        checkStart
    {
        require(amount > 0, 'LPTokenSharePool(USDT-OSC): Cannot stake 0');
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkhalve
        checkStart
    {
        require(amount > 0, 'LPTokenSharePool(USDT-OSC): Cannot withdraw 0');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkhalve checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            uint256 fundPaid = reward.mul(RISK_FUND_PERCENT).div(100);// 3%
            uint256 devPaid = reward.mul(DEV_FUND_PERCENT).div(100);// 2%
            uint256 rebate = reward.mul(REFERRAL_REBATE_PERCENT).div(100); // 1%
            uint256 actualPaid = reward;

            if(riskFundAddress != address(0) && fundPaid > 0){
               actualPaid = actualPaid.sub(fundPaid);
               oscarShare.safeTransfer(riskFundAddress, fundPaid);
               emit RiskFundRewardPaid(riskFundAddress, fundPaid);     
            }

            if(devFundAddress != address(0) && devPaid > 0){
               actualPaid = actualPaid.sub(devPaid);
               oscarShare.safeTransfer(devFundAddress, devPaid);
               emit DevFundRewardPaid(devFundAddress, devPaid);     
            }

            if (rewardReferral != address(0) && rebate > 0) {
                address referrer = IReferral(rewardReferral).getReferrer(msg.sender);
                if(referrer != address(0)){
                    actualPaid = actualPaid.sub(rebate);
                    oscarShare.safeTransfer(referrer, rebate);
                    emit ReferralRewardPaid(msg.sender, referrer, rebate);
                }
            }

            oscarShare.safeTransfer(msg.sender, actualPaid);
            emit RewardPaid(msg.sender, actualPaid);
        }
    }

    modifier checkhalve() {
        if (block.timestamp >= periodFinish) {
            initreward = initreward.mul(75).div(100);

            rewardRate = initreward.div(DURATION);
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(initreward);
        }
        _;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, 'LPTokenSharePool(USDT-OSC): not start');
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = initreward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }

        _checkRewardRate();
    }

    function _checkRewardRate() internal view returns (uint256) {
        return DURATION.mul(rewardRate).mul(1e18);
    }
}
