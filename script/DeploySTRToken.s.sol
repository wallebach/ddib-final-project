// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/STRToken.sol";

contract DeploySTRToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        STRToken strToken = new STRToken();
        
        console.log("STRToken deployed at:", address(strToken));
        console.log("Token Name:", strToken.name());
        console.log("Token Symbol:", strToken.symbol());
        console.log("Deployer:", msg.sender);
        
        vm.stopBroadcast();
    }
}