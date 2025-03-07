// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TsundereToken} from "../src/TsundereToken.sol";

contract TsundereTokenScript is Script {
    TsundereToken baaka;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        baaka = new TsundereToken(1000, 10000, 10);

        vm.stopBroadcast();
    }
}
