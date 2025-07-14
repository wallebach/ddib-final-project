// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SubscriptionPlatform} from "../src/SubscriptionPlatform.sol";
import {STRToken} from "../src/STRToken.sol";
import {GRNToken} from "../src/GRNToken.sol";
import {PlatformGovernance} from "../src/PlatformGovernance.sol";

contract Redeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        STRToken strToken = new STRToken();
        strToken.addMinter(deployer);
        
        GRNToken grnToken = new GRNToken(
            deployer, // creatorRewardPool
            deployer, // daoTreasury  
            deployer, // teamAndAdvisors
            deployer, // communityRewards
            deployer  // liquidityPool
        );
        
        SubscriptionPlatform subscriptionPlatform = new SubscriptionPlatform(
            address(strToken),
            address(grnToken),
            deployer, // creatorRewardPool
            deployer, // daoTreasury
            deployer  // grnAccrualPool
        );
        
        PlatformGovernance platformGovernance = new PlatformGovernance(
            address(grnToken)
        );
        
        strToken.mint(deployer, 1000000e18);
        
        vm.stopBroadcast();
        
        string memory obj = "deployment";
        vm.serializeString(obj, "STRToken", vm.toString(address(strToken)));
        vm.serializeString(obj, "GRNToken", vm.toString(address(grnToken)));
        vm.serializeString(obj, "SubscriptionPlatform", vm.toString(address(subscriptionPlatform)));
        vm.serializeString(obj, "PlatformGovernance", vm.toString(address(platformGovernance)));
        vm.serializeString(obj, "deployerAddress", vm.toString(deployer));
        vm.serializeString(obj, "network", "localhost");
        string memory finalJson = vm.serializeString(obj, "chainId", "31337");
        
        vm.writeJson(finalJson, "./contracts.json");
    }
}