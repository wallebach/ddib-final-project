// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/STRToken.sol";
import "../src/GRNToken.sol";
import "../src/SubscriptionPlatform.sol";
import "../src/PlatformGovernance.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        STRToken strToken = new STRToken();
        console.log("STRToken deployed at:", address(strToken));
        
        address deployer = vm.addr(deployerPrivateKey);
        
        address creatorRewardPool = deployer;
        address daoTreasury = deployer;
        address grnAccrualPool = deployer;
        address teamAndAdvisors = deployer;
        address communityRewards = deployer;
        address liquidityPool = deployer;
        
        GRNToken grnToken = new GRNToken(
            creatorRewardPool,
            daoTreasury,
            teamAndAdvisors,
            communityRewards,
            liquidityPool
        );
        console.log("GRNToken deployed at:", address(grnToken));
        
        SubscriptionPlatform platform = new SubscriptionPlatform(
            address(strToken),
            address(grnToken),
            creatorRewardPool,
            daoTreasury,
            grnAccrualPool
        );
        console.log("SubscriptionPlatform deployed at:", address(platform));
        
        PlatformGovernance governance = new PlatformGovernance(
            address(grnToken)
        );
        console.log("PlatformGovernance deployed at:", address(governance));
        
        strToken.addMinter(address(platform));
        strToken.addMinter(deployer); 
        
        strToken.mint(deployer, 10000 * 10**18); 
        
        grnToken.approve(address(platform), type(uint256).max);
        
        console.log("=== Deployment Summary ===");
        console.log("STRToken:", address(strToken));
        console.log("GRNToken:", address(grnToken));
        console.log("SubscriptionPlatform:", address(platform));
        console.log("PlatformGovernance:", address(governance));
        console.log("Deployer STR Balance:", strToken.balanceOf(deployer));
        console.log("Deployer GRN Balance:", grnToken.balanceOf(deployer));
        
        vm.stopBroadcast();
    }
}