pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../interfaces/IRewardDistributionRecipient.sol';
import '../interfaces/IReferral.sol';

contract OSBWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public osb;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        osb.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        osb.safeTransfer(msg.sender, amount);
    }
}

contract OSSOSBPool is OSBWrapper, IRewardDistributionRecipient {

    IERC20 public oscarShare;
    uint256 public constant DURATION = 365 days;
    uint256 public constant REFERRAL_REBATE_PERCENT = 1;
    uint256 public constant RISK_FUND_PERCENT = 2;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    address public riskFundAddress;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public deposits;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event FundRewardPaid(address indexed user, uint256 reward);
    event ReferralRewardPaid(address indexed user, address indexed referral, uint256 reward);

    constructor(
        address oscarShare_,
        address osb_,
        address riskFundAddress_,
        uint256 starttime_
    ) public {
        oscarShare = IERC20(oscarShare_);
        osb = IERC20(osb_);
        riskFundAddress = riskFundAddress_;
        starttime = starttime_;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, 'OSSOSBPool: not start');
        _;
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
        checkStart
    {
        require(amount > 0, 'OSSOSBPool: Cannot stake 0');
        uint256 newDeposit = deposits[msg.sender].add(amount);
       
        deposits[msg.sender] = newDeposit;
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'OSSOSBPool: Cannot withdraw 0');
        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            uint256 fundPaid = reward.mul(RISK_FUND_PERCENT).div(100);// 2%
            uint256 rebate = reward.mul(REFERRAL_REBATE_PERCENT).div(100); // 1%
            uint256 actualPaid =reward;

            if(riskFundAddress != address(0) && fundPaid > 0){
               actualPaid = actualPaid.sub(fundPaid);
               oscarShare.safeTransfer(riskFundAddress, fundPaid);
               emit FundRewardPaid(riskFundAddress, fundPaid);     
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
            rewardRate = reward.div(DURATION);
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
