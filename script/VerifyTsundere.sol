// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {TsundereToken} from "../src/TsundereToken.sol";

contract TestTsundereScript is Script {
    TsundereToken token;
    address contractAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Second hardhat account
    address user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Third hardhat account
    uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Default hardhat #0 private key

    function setUp() public {
        vm.createSelectFork("http://localhost:8545");
        token = TsundereToken(contractAddress);
    }

    function run() public {
        // 1. Basic token properties
        testBasicProperties();
        
        // 2. Test transfers
        testTransfers();
        
        // 3. Test approvals and transferFrom
        testApprovals();
        
        // 4. Test faucet functionality
        testFaucet();
        
        // 5. Test owner functions
        testOwnerFunctions();
    }

    function testBasicProperties() internal view {
        console2.log("=== BASIC TOKEN PROPERTIES ===");
        console2.log("Token name:", token.name());
        console2.log("Token symbol:", token.symbol());
        console2.log("Decimals:", token.decimals());
        console2.log("Total supply:", token.totalSupply());
        console2.log("Supply cap:", token.cap());
        console2.log("Owner:", token.owner());
        console2.log("Deployer balance:", token.balanceOf(deployer));
        console2.log("Is paused:", token.paused());
        console2.log("Faucet amount:", token.faucetAmount());
        console2.log("");
    }

    function testTransfers() internal {
        console2.log("=== TESTING TRANSFERS ===");
        uint256 initialBalance = token.balanceOf(deployer);
        console2.log("Initial deployer balance:", initialBalance);
        
        // Start broadcasting transactions (using deployer's private key)
        vm.startBroadcast(deployerPrivateKey);
        
        // Transfer 10 tokens from deployer to user1
        uint256 transferAmount = 10 * 10**18;
        bool transferSuccess = token.transfer(user1, transferAmount);
        
        vm.stopBroadcast();
        
        console2.log("Transfer 10 tokens to user1 successful:", transferSuccess);
        console2.log("New deployer balance:", token.balanceOf(deployer));
        console2.log("User1 balance:", token.balanceOf(user1));
        console2.log("");
    }

    function testApprovals() internal {
        console2.log("=== TESTING APPROVALS & TRANSFERFROM ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve user1 to spend 5 tokens on behalf of deployer
        uint256 approvalAmount = 5 * 10**18;
        bool approvalSuccess = token.approve(user1, approvalAmount);
        
        vm.stopBroadcast();
        
        console2.log("Approval to user1 successful:", approvalSuccess);
        console2.log("User1's allowance from deployer:", token.allowance(deployer, user1));
        
        // Use user1's private key to execute transferFrom
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d); // user1 private key
        
        // user1 transfers 2 tokens from deployer to user2
        uint256 transferFromAmount = 2 * 10**18;
        bool transferFromSuccess = false;
        
        try token.transferFrom(deployer, user2, transferFromAmount) returns (bool success) {
            transferFromSuccess = success;
        } catch {
            console2.log("TransferFrom failed (expected if using a forked chain without impersonation)");
        }
        
        vm.stopBroadcast();
        
        console2.log("TransferFrom successful:", transferFromSuccess);
        console2.log("Deployer balance after transferFrom:", token.balanceOf(deployer));
        console2.log("User2 balance after transferFrom:", token.balanceOf(user2));
        console2.log("Remaining allowance:", token.allowance(deployer, user1));
        console2.log("");
    }

    function testFaucet() internal {
        console2.log("=== TESTING FAUCET ===");
        
        // Check if user2 already claimed
        bool hasClaimedBefore = token.hasClaimedFaucet(user2);
        console2.log("User2 has claimed before:", hasClaimedBefore);
        
        // Impersonate user2 to claim from faucet
        vm.startPrank(user2);
        
        bool faucetSuccess = false;
        try token.claimFaucet() returns (bool success) {
            faucetSuccess = success;
        } catch {
            console2.log("Faucet claim failed (expected if user already claimed)");
        }
        
        vm.stopPrank();
        
        console2.log("Faucet claim successful:", faucetSuccess);
        console2.log("User2 balance after faucet:", token.balanceOf(user2));
        console2.log("User2 has claimed now:", token.hasClaimedFaucet(user2));
        console2.log("");
    }

    function testOwnerFunctions() internal {
        console2.log("=== TESTING OWNER FUNCTIONS ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Test minting new tokens
        uint256 mintAmount = 1000 * 10**18;
        bool mintSuccess = false;
        
        try token.mint(user1, mintAmount) returns (bool success) {
            mintSuccess = success;
        } catch {
            console2.log("Mint failed (check if deployer is owner)");
        }
        
        console2.log("Mint successful:", mintSuccess);
        console2.log("User1 balance after mint:", token.balanceOf(user1));
        console2.log("Total supply after mint:", token.totalSupply());
        
        // Test pause/unpause
        try token.pause() {
            console2.log("Contract paused successfully");
            console2.log("Is paused now:", token.paused());
            
            // Try to unpause
            token.unpause();
            console2.log("Contract unpaused successfully");
            console2.log("Is paused now:", token.paused());
        } catch {
            console2.log("Pause failed (check if deployer is owner)");
        }
        
        vm.stopBroadcast();
    }
}