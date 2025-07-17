// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/utils/math/SafeMath.sol";

interface IPriceOracle {
    function getETHUSDPrice() external view returns (uint256);
}

contract STRToken is ERC20, ERC20Burnable, ERC20Permit, Ownable, Pausable {
    using SafeMath for uint256;
    
    mapping(address => bool) public minters;
    
    // Price peg mechanism
    IPriceOracle public priceOracle;
    uint256 public constant TARGET_PRICE = 1e8; // $1.00 in 8 decimals
    uint256 public collateralRatio = 150; // 150% collateralization
    uint256 public constant COLLATERAL_RATIO_PRECISION = 100;
    
    // Reserves
    uint256 public totalCollateral; // ETH collateral backing STR
    mapping(address => uint256) public userCollateral; // User's ETH deposits
    
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event STRMinted(address indexed user, uint256 strAmount, uint256 ethDeposited);
    event STRRedeemed(address indexed user, uint256 strAmount, uint256 ethReturned);
    event CollateralRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);
    
    constructor() ERC20("STR Token", "STR") ERC20Permit("STR Token") {}
    
    modifier onlyMinter() {
        require(minters[msg.sender], "STR: caller is not a minter");
        _;
    }
    
    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }
    
    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }
    
    function mint(address to, uint256 amount) external onlyMinter whenNotPaused {
        _mint(to, amount);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function setOracle(address _oracle) external onlyOwner {
        address oldOracle = address(priceOracle);
        priceOracle = IPriceOracle(_oracle);
        emit OracleUpdated(oldOracle, _oracle);
    }
    
    function setCollateralRatio(uint256 _ratio) external onlyOwner {
        require(_ratio >= 100, "STR: ratio must be at least 100%");
        uint256 oldRatio = collateralRatio;
        collateralRatio = _ratio;
        emit CollateralRatioUpdated(oldRatio, _ratio);
    }
    
    function mintWithETH() external payable whenNotPaused {
        require(msg.value > 0, "STR: must send ETH");
        require(address(priceOracle) != address(0), "STR: oracle not set");
        
        uint256 ethPrice = priceOracle.getETHUSDPrice(); 
        uint256 ethValueUSD = msg.value.mul(ethPrice).div(1e18);
        
        uint256 strToMint = ethValueUSD.mul(COLLATERAL_RATIO_PRECISION).div(collateralRatio);
        
        strToMint = strToMint.mul(1e18).div(1e8);
        
        require(strToMint > 0, "STR: insufficient ETH value");
        
        totalCollateral = totalCollateral.add(msg.value);
        userCollateral[msg.sender] = userCollateral[msg.sender].add(msg.value);
        
        _mint(msg.sender, strToMint);
        
        emit STRMinted(msg.sender, strToMint, msg.value);
    }
    
    function redeemForETH(uint256 strAmount) external whenNotPaused {
        require(strAmount > 0, "STR: amount must be positive");
        require(balanceOf(msg.sender) >= strAmount, "STR: insufficient balance");
        require(address(priceOracle) != address(0), "STR: oracle not set");
        
        uint256 ethPrice = priceOracle.getETHUSDPrice();
        
        uint256 usdValue = strAmount.mul(1e8).div(1e18); 
        
        uint256 ethToReturn = usdValue.mul(1e18).div(ethPrice); 
        
        require(ethToReturn <= address(this).balance, "STR: insufficient ETH reserves");
        require(ethToReturn <= userCollateral[msg.sender], "STR: insufficient user collateral");
        
        totalCollateral = totalCollateral.sub(ethToReturn);
        userCollateral[msg.sender] = userCollateral[msg.sender].sub(ethToReturn);
        
        _burn(msg.sender, strAmount);
        
        payable(msg.sender).transfer(ethToReturn);
        
        emit STRRedeemed(msg.sender, strAmount, ethToReturn);
    }
    
    function getCollateralRatio() external view returns (uint256) {
        if (totalSupply() == 0) return 0;
        
        uint256 ethPrice = priceOracle.getETHUSDPrice();
        uint256 totalCollateralUSD = totalCollateral.mul(ethPrice).div(1e18);
        uint256 totalSupplyUSD = totalSupply().mul(1e8).div(1e18);
        
        return totalCollateralUSD.mul(100).div(totalSupplyUSD);
    }
    
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}