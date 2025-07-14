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

contract STRToken is ERC20, ERC20Burnable, ERC20Permit, Ownable, Pausable {
    using SafeMath for uint256;
    
    mapping(address => bool) public minters;
    
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    
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
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}