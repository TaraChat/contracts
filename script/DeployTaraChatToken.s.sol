// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TaraChatToken} from "../src/Token.sol";

contract DeployTaraChatToken is Script {
    function run() external {
        address deployer = vm.envAddress("DEPLOYER");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TaraChatToken contract
        TaraChatToken token = new TaraChatToken(deployer);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        console.log("TaraChatToken deployed at:", address(token));
    }
}
