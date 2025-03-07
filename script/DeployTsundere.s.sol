// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TsundereToken} from "../src/TsundereToken.sol";

contract TsundereTokenScript is Script {
    TsundereToken baaka;

    function setUp() public {
        vm.createFork("https://sepolia.infura.io/v3/896b4d017a404e5885f0ef28995ad3b9");
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        console.log("Account ::", privateKey);
        vm.startBroadcast(privateKey);

        baaka = new TsundereToken(1000, 10000, 10);

        vm.stopBroadcast();
    }
}
