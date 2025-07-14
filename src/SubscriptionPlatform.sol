// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/utils/math/SafeMath.sol";

import "src/GRNToken.sol";
import "src/STRToken.sol";

contract SubscriptionPlatform is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    
    STRToken public strToken;
    GRNToken public grnToken;
    
    uint256 public constant MONTHLY_DURATION = 30 days;
    uint256 public constant YEARLY_DURATION = 365 days;
    
    uint256 public creatorRewardBps = 6000; 
    uint256 public daoTreasuryBps = 2500; 
    uint256 public grnAccrualBps = 1500; 
    

    address public creatorRewardPool;
    address public daoTreasury;
    address public grnAccrualPool;
    
    struct CreatorInfo {
        bool isRegistered;
        string name;
        uint256 monthlyPrice;
        uint256 yearlyPrice;
        uint256 totalEarnings;
        uint256 subscriberCount;
    }
    
    
    struct Subscription {
        uint256 expirationTime;
        bool active;
        bool isYearly;
    }
    
    mapping(address => CreatorInfo) public creators;
    mapping(address => mapping(address => Subscription)) public subscriptions; 
    mapping(address => address[]) public userSubscribedCreators; 
    mapping(address => address[]) public creatorSubscribers; 
    
    mapping(address => uint256) public stakedSTR;
    mapping(address => uint256) public stakingTimestamp;
    uint256 public constant STAKING_REWARD_RATE = 10000; 
    
    event SubscriptionPurchased(address indexed subscriber, address indexed creator, uint256 amount, uint256 expiration, bool isYearly);
    event CreatorRegistered(address indexed creator, string name, uint256 monthlyPrice, uint256 yearlyPrice);
    event CreatorPricesUpdated(address indexed creator, uint256 monthlyPrice, uint256 yearlyPrice);
    event CreatorEarningsWithdrawn(address indexed creator, uint256 amount);
    event STRStaked(address indexed user, uint256 amount);
    event STRUnstaked(address indexed user, uint256 amount);
    event GRNRewardClaimed(address indexed user, uint256 amount);
    event RevenueDistributed(uint256 creatorAmount, uint256 daoAmount, uint256 grnAmount);
    
    constructor(
        address _strToken,
        address _grnToken,
        address _creatorRewardPool,
        address _daoTreasury,
        address _grnAccrualPool
    ) {
        require(_strToken != address(0), "Invalid STR token address");
        require(_grnToken != address(0), "Invalid GRN token address");
        require(_creatorRewardPool != address(0), "Invalid creator reward pool");
        require(_daoTreasury != address(0), "Invalid DAO treasury");
        require(_grnAccrualPool != address(0), "Invalid GRN accrual pool");
        
        strToken = STRToken(_strToken);
        grnToken = GRNToken(_grnToken);
        creatorRewardPool = _creatorRewardPool;
        daoTreasury = _daoTreasury;
        grnAccrualPool = _grnAccrualPool;
    }
    
    function registerCreator(string memory _name, uint256 _monthlyPrice, uint256 _yearlyPrice) external {
        require(!creators[msg.sender].isRegistered, "Already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_monthlyPrice > 0, "Monthly price must be greater than 0");
        require(_yearlyPrice > 0, "Yearly price must be greater than 0");
        
        creators[msg.sender] = CreatorInfo({
            isRegistered: true,
            name: _name,
            monthlyPrice: _monthlyPrice,
            yearlyPrice: _yearlyPrice,
            totalEarnings: 0,
            subscriberCount: 0
        });
        
        emit CreatorRegistered(msg.sender, _name, _monthlyPrice, _yearlyPrice);
    }
    
    function updateCreatorPrices(uint256 _monthlyPrice, uint256 _yearlyPrice) external {
        require(creators[msg.sender].isRegistered, "Not a registered creator");
        require(_monthlyPrice > 0, "Monthly price must be greater than 0");
        require(_yearlyPrice > 0, "Yearly price must be greater than 0");
        
        creators[msg.sender].monthlyPrice = _monthlyPrice;
        creators[msg.sender].yearlyPrice = _yearlyPrice;
        
        emit CreatorPricesUpdated(msg.sender, _monthlyPrice, _yearlyPrice);
    }
    
    function subscribeToCreator(address creator, bool isYearly) external nonReentrant whenNotPaused {
        require(creators[creator].isRegistered, "Creator not registered");
        
        uint256 price = isYearly ? creators[creator].yearlyPrice : creators[creator].monthlyPrice;
        uint256 duration = isYearly ? YEARLY_DURATION : MONTHLY_DURATION;
        
        require(strToken.balanceOf(msg.sender) >= price, "Insufficient STR balance");
        
        bool isNewSubscription = !subscriptions[msg.sender][creator].active || 
                                subscriptions[msg.sender][creator].expirationTime <= block.timestamp;
        
        strToken.transferFrom(msg.sender, address(this), price);
        
        subscriptions[msg.sender][creator] = Subscription({
            expirationTime: block.timestamp.add(duration),
            active: true,
            isYearly: isYearly
        });
        
        if (isNewSubscription) {
            userSubscribedCreators[msg.sender].push(creator);
            creatorSubscribers[creator].push(msg.sender);
            creators[creator].subscriberCount = creators[creator].subscriberCount.add(1);
        }
        
        _distributeRevenue(creator, price);
        
        emit SubscriptionPurchased(msg.sender, creator, price, block.timestamp.add(duration), isYearly);
    }
    
    function _distributeRevenue(address creator, uint256 amount) internal {
        uint256 creatorAmount = amount.mul(creatorRewardBps).div(10000);
        uint256 daoAmount = amount.mul(daoTreasuryBps).div(10000);
        uint256 grnAmount = amount.mul(grnAccrualBps).div(10000);
        
        creators[creator].totalEarnings = creators[creator].totalEarnings.add(creatorAmount);
        
        strToken.transfer(daoTreasury, daoAmount);
        strToken.transfer(grnAccrualPool, grnAmount);
        
        emit RevenueDistributed(creatorAmount, daoAmount, grnAmount);
    }
    
    function stakeSTR(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(strToken.balanceOf(msg.sender) >= amount, "Insufficient STR balance");
        
        strToken.transferFrom(msg.sender, address(this), amount);
        
        stakedSTR[msg.sender] = stakedSTR[msg.sender].add(amount);
        
        if (stakingTimestamp[msg.sender] == 0) {
            stakingTimestamp[msg.sender] = block.timestamp;
        }
        
        emit STRStaked(msg.sender, amount);
    }
    
    function unstakeSTR(uint256 amount) external nonReentrant {
        require(stakedSTR[msg.sender] >= amount, "Insufficient staked amount");
        
        stakedSTR[msg.sender] = stakedSTR[msg.sender].sub(amount);
        
        strToken.transfer(msg.sender, amount);
        
        emit STRUnstaked(msg.sender, amount);
    }
    
    function claimGRNRewards() external nonReentrant {
        uint256 reward = calculateGRNReward(msg.sender);
        require(reward > 0, "No rewards to claim");
        
        stakingTimestamp[msg.sender] = block.timestamp;

        require(grnToken.balanceOf(grnAccrualPool) >= reward, "Insufficient GRN in reward pool");
        grnToken.transferFrom(grnAccrualPool, msg.sender, reward);
        
        emit GRNRewardClaimed(msg.sender, reward);
    }
    
    function calculateGRNReward(address user) public view returns (uint256) {
        if (stakedSTR[user] == 0) return 0;
        
        uint256 stakingTime = block.timestamp.sub(stakingTimestamp[user]);
        uint256 annualReward = stakedSTR[user].mul(STAKING_REWARD_RATE).div(10000);
        
        return annualReward.mul(stakingTime).div(60);
    }
    
    function isSubscriptionActive(address subscriber, address creator) external view returns (bool) {
        return subscriptions[subscriber][creator].active && 
               subscriptions[subscriber][creator].expirationTime > block.timestamp;
    }
    
    function withdrawCreatorEarnings() external nonReentrant {
        require(creators[msg.sender].isRegistered, "Not a registered creator");
        uint256 earnings = creators[msg.sender].totalEarnings;
        require(earnings > 0, "No earnings to withdraw");
        
        creators[msg.sender].totalEarnings = 0;
        strToken.transfer(msg.sender, earnings);
        
        emit CreatorEarningsWithdrawn(msg.sender, earnings);
    }
    
    function getCreatorInfo(address creator) external view returns (
        bool isRegistered,
        string memory name,
        uint256 monthlyPrice,
        uint256 yearlyPrice,
        uint256 totalEarnings,
        uint256 subscriberCount
    ) {
        CreatorInfo memory info = creators[creator];
        return (info.isRegistered, info.name, info.monthlyPrice, info.yearlyPrice, info.totalEarnings, info.subscriberCount);
    }
    
    function getUserSubscribedCreators(address user) external view returns (address[] memory) {
        return userSubscribedCreators[user];
    }
    
    function getCreatorSubscribers(address creator) external view returns (address[] memory) {
        return creatorSubscribers[creator];
    }
    
    // Admin functions (removed setSubscriptionPrices since creators set their own)
    
    function setRevenueSplit(uint256 _creatorBps, uint256 _daoBps, uint256 _grnBps) external onlyOwner {
        require(_creatorBps.add(_daoBps).add(_grnBps) == 10000, "Split must equal 100%");
        creatorRewardBps = _creatorBps;
        daoTreasuryBps = _daoBps;
        grnAccrualBps = _grnBps;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
}