// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/math/SafeMath.sol";

contract GRNToken is ERC20, ERC20Permit, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 10**18; 
    
    address public creatorIncentivePool;
    address public daoTreasury;
    address public teamAndAdvisors;
    address public communityRewards;
    address public liquidityPool;
    
    uint256 public teamVestingStart;
    uint256 public constant VESTING_DURATION = 4 * 365 days;
    uint256 public teamTokensReleased;
    
    event TokensVested(address indexed beneficiary, uint256 amount);
    
    constructor(
        address _creatorIncentivePool,
        address _daoTreasury,
        address _teamAndAdvisors,
        address _communityRewards,
        address _liquidityPool
    ) ERC20("GRN Token", "GRN") ERC20Permit("GRN Token") {
        require(_creatorIncentivePool != address(0), "Invalid creator pool address");
        require(_daoTreasury != address(0), "Invalid DAO treasury address");
        require(_teamAndAdvisors != address(0), "Invalid team address");
        require(_communityRewards != address(0), "Invalid community rewards address");
        require(_liquidityPool != address(0), "Invalid liquidity pool address");
        
        creatorIncentivePool = _creatorIncentivePool;
        daoTreasury = _daoTreasury;
        teamAndAdvisors = _teamAndAdvisors;
        communityRewards = _communityRewards;
        liquidityPool = _liquidityPool;
        
        teamVestingStart = block.timestamp;
        
        _mint(_creatorIncentivePool, TOTAL_SUPPLY.mul(30).div(100)); 
        _mint(_daoTreasury, TOTAL_SUPPLY.mul(25).div(100)); 
        _mint(address(this), TOTAL_SUPPLY.mul(20).div(100)); 
        _mint(_communityRewards, TOTAL_SUPPLY.mul(15).div(100)); 
        _mint(_liquidityPool, TOTAL_SUPPLY.mul(10).div(100)); 
    }
    
    function releaseVestedTokens() external {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "No tokens to release");
        
        teamTokensReleased = teamTokensReleased.add(unreleased);
        _transfer(address(this), teamAndAdvisors, unreleased);
        
        emit TokensVested(teamAndAdvisors, unreleased);
    }
    
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(teamTokensReleased);
    }
    
    function vestedAmount() public view returns (uint256) {
        uint256 totalBalance = TOTAL_SUPPLY.mul(20).div(100);
        
        if (block.timestamp < teamVestingStart) {
            return 0;
        } else if (block.timestamp >= teamVestingStart.add(VESTING_DURATION)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(teamVestingStart)).div(VESTING_DURATION);
        }
    }
}
