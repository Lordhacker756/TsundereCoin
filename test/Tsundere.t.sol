// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TsundereToken} from "../src/TsundereToken.sol";

contract TsundereTokenTest is Test {
    TsundereToken baaka;

    function setUp() public {
        // Initialize with a fixed supply for regular tests
        baaka = new TsundereToken(1000, 10000, 10); //We provide in integer form, it's converted to 10e18
    }

    function testTotalSupply() public view {
        assertEq(baaka.totalSupply(), 1000 * 10 ** 18);
    }

    function testTotalCap() public view {
        assertEq(baaka.cap(), 10000 * 10 ** 18);
    }

    function testFacuetAmount() public view {
        assertEq(baaka.faucetAmount(), 10 * 10 ** 18);
    }

    function testBalanceOf() public view {
        assertEq(baaka.balanceOf(address(this)), 1000 * 10 ** 18);
    }

    function testIsNotPaused() public view {
        assertEq(baaka.paused(), false);
    }

    function testPause() public {
        baaka.pause();
        assertEq(baaka.paused(), true);
    }

    //TODO: Test cases for transfer tokens
    //* Should Pass these tests
    function testTransferToAddress1() public {
        baaka.transfer(address(0x1), 100);
        assertEq(baaka.balanceOf(address(0x1)), 100);
    }

    //! Should fail these tests
    function test_RevertWhen_TransferToZeroAddress() public {
        vm.expectRevert(); // Expects any revert
        baaka.transfer(address(0), 100);
    }

    function test_RevertWhen_TransferWhenPaused() public {
        baaka.pause();
        vm.expectRevert(); // Expects any revert
        baaka.transfer(address(0x1), 100);
    }

    function test_RevertWhen_TransferMoreThanBalance() public {
        vm.expectRevert(); // Expects any revert
        baaka.transfer(address(0x1), 11000000000000000000000001);
    }

    function test_RevertWhen_TransferZeroAmount() public {
        vm.expectRevert(); // Expects any revert
        baaka.transfer(address(0x1), 0);
    }

    //TODO: Approval Tests
    //* Should Pass these tests
    function testGiveApproval() public {
        baaka.approve(address(0x1), 100);
        assertEq(baaka.allowance(address(this), address(0x1)), 100);
    }

    //! Should fail these tests
    function test_RevertWhen_ApprovalToZeroAddress() public {
        vm.expectRevert();
        baaka.approve(address(0), 100);
    }

    function test_RevertWhen_AllowToSelf() public {
        vm.expectRevert();
        baaka.approve(address(this), 100);
    }

    function test_RevertWhen_ApprovingMoreThanBalance() public {
        vm.expectRevert();
        baaka.approve(address(this), 11000000000000000000000001);
    }

    //TODO: Transfer from test cases
    //* These should pass
    function testTransferFromOneToTwo() public {
        baaka.approve(address(0x1), 100);
        assertEq(baaka.allowance(address(this), address(0x1)), 100);

        vm.prank(address(0x1));
        baaka.transferFrom(address(this), address(0x2), 100);

        // Verify the transfer worked
        assertEq(baaka.balanceOf(address(0x2)), 100);
    }

    //! These should fail
    function test_RevertWhen_TransferFromToZeroAddress() public {
        baaka.approve(address(0x1), 100);

        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.transferFrom(address(this), address(0), 100);
    }

    function test_RevertWhen_TransferFromZeroAddress() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.transferFrom(address(0), address(0x2), 100);
    }

    function test_RevertWhen_TransferFromZeroAmount() public {
        baaka.approve(address(0x1), 100);

        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.transferFrom(address(this), address(0x2), 0);
    }

    function test_RevertWhen_TransferFromExceedsAllowance() public {
        baaka.approve(address(0x1), 100);

        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.transferFrom(address(this), address(0x2), 101);
    }

    function test_RevertWhen_TransferFromExceedsBalance() public {
        // Give address(0x3) approval to spend a huge amount from this contract
        baaka.approve(address(0x3), 1000000000000000000000);

        vm.prank(address(0x3));
        vm.expectRevert();
        baaka.transferFrom(
            address(this),
            address(0x2),
            11000000000000000000000001
        );
    }

    function test_RevertWhen_TransferFromWhenPaused() public {
        baaka.approve(address(0x1), 100);
        baaka.pause();

        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.transferFrom(address(this), address(0x2), 100);
    }

    //TODO: Allowance Modification Tests
    //* These should pass
    function testIncreaseAllowance() public {
        baaka.approve(address(0x1), 100);
        baaka.increaseAllowance(address(0x1), 50);
        assertEq(baaka.allowance(address(this), address(0x1)), 150);
    }

    function testDecreaseAllowance() public {
        baaka.approve(address(0x1), 100);
        baaka.decreaseAllowance(address(0x1), 50);
        assertEq(baaka.allowance(address(this), address(0x1)), 50);
    }

    //! These should fail
    function test_RevertWhen_IncreaseAllowanceToZeroAddress() public {
        vm.expectRevert();
        baaka.increaseAllowance(address(0), 100);
    }

    function test_RevertWhen_IncreaseAllowanceZeroAmount() public {
        vm.expectRevert();
        baaka.increaseAllowance(address(0x1), 0);
    }

    function test_RevertWhen_IncreaseAllowanceWhenPaused() public {
        baaka.pause();
        vm.expectRevert();
        baaka.increaseAllowance(address(0x1), 100);
    }

    function test_RevertWhen_DecreaseAllowanceToZeroAddress() public {
        vm.expectRevert();
        baaka.decreaseAllowance(address(0), 100);
    }

    function test_RevertWhen_DecreaseAllowanceZeroAmount() public {
        vm.expectRevert();
        baaka.decreaseAllowance(address(0x1), 0);
    }

    function test_RevertWhen_DecreaseAllowanceMoreThanAllowed() public {
        baaka.approve(address(0x1), 100);

        vm.expectRevert();
        baaka.decreaseAllowance(address(0x1), 101);
    }

    function test_RevertWhen_DecreaseAllowanceWhenPaused() public {
        baaka.approve(address(0x1), 100);
        baaka.pause();

        vm.expectRevert();
        baaka.decreaseAllowance(address(0x1), 50);
    }

    //TODO: Mint Tests
    //* These should pass
    function testMint() public {
        baaka.mint(address(0x1), 100);
        assertEq(baaka.balanceOf(address(0x1)), 100);
        assertEq(baaka.totalSupply(), 1000 * 10 ** 18 + 100);
    }

    //! These should fail
    function test_RevertWhen_MintToZeroAddress() public {
        vm.expectRevert();
        baaka.mint(address(0), 100);
    }

    function test_RevertWhen_MintZeroAmount() public {
        vm.expectRevert();
        baaka.mint(address(0x1), 0);
    }

    function test_RevertWhen_MintWhenPaused() public {
        baaka.pause();

        vm.expectRevert();
        baaka.mint(address(0x1), 100);
    }

    function test_RevertWhen_MintExceedsCap() public {
        uint256 remainingToMint = baaka.cap() - baaka.totalSupply();

        vm.expectRevert();
        baaka.mint(address(0x1), remainingToMint + 1);
    }

    function test_RevertWhen_NonOwnerMints() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.mint(address(0x2), 100);
    }

    //TODO: Burn Tests
    //* These should pass
    function testBurn() public {
        uint256 initialSupply = baaka.totalSupply();
        uint256 initialBalance = baaka.balanceOf(address(this));

        baaka.burn(100);

        assertEq(baaka.balanceOf(address(this)), initialBalance - 100);
        assertEq(baaka.totalSupply(), initialSupply - 100);
    }

    //! These should fail
    function test_RevertWhen_BurnZeroAmount() public {
        vm.expectRevert();
        baaka.burn(0);
    }

    function test_RevertWhen_BurnMoreThanBalance() public {
        uint256 balance = baaka.balanceOf(address(this));

        vm.expectRevert();
        baaka.burn(balance + 1);
    }

    function test_RevertWhen_BurnWhenPaused() public {
        baaka.pause();

        vm.expectRevert();
        baaka.burn(100);
    }

    //TODO: Pause/Unpause Tests
    //* These should pass
    function testUnpause() public {
        baaka.pause();
        assertEq(baaka.paused(), true);

        baaka.unpause();
        assertEq(baaka.paused(), false);
    }

    //! These should fail
    function test_RevertWhen_NonOwnerPauses() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.pause();
    }

    function test_RevertWhen_NonOwnerUnpauses() public {
        baaka.pause();

        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.unpause();
    }

    //TODO: Ownership Tests
    //* These should pass
    function testTransferOwnership() public {
        baaka.transferOwnership(address(0x1));
        assertEq(baaka.owner(), address(0x1));
    }

    //! These should fail
    function test_RevertWhen_TransferOwnershipToZeroAddress() public {
        vm.expectRevert();
        baaka.transferOwnership(address(0));
    }

    function test_RevertWhen_NonOwnerTransfersOwnership() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        baaka.transferOwnership(address(0x2));
    }

    //TODO: Faucet Tests
    //* These should pass
    function testFaucetClaim() public {
        // Use a different address to claim
        vm.startPrank(address(0x3));
        uint256 initialBalance = baaka.balanceOf(address(0x3));
        uint256 faucetAmount = baaka.faucetAmount();

        baaka.claimFaucet();

        assertEq(baaka.balanceOf(address(0x3)), initialBalance + faucetAmount);
        assertTrue(baaka.hasClaimedFaucet(address(0x3)));
        vm.stopPrank();
    }

    //! These should fail
    function test_RevertWhen_DoubleClaimFaucet() public {
        vm.startPrank(address(0x4));
        baaka.claimFaucet();

        vm.expectRevert();
        baaka.claimFaucet();
        vm.stopPrank();
    }

    function test_RevertWhen_FaucetClaimWhenPaused() public {
        baaka.pause();

        vm.prank(address(0x5));
        vm.expectRevert();
        baaka.claimFaucet();
    }

    function test_RevertWhen_FaucetClaimExceedsCap() public {
        // Create a new TsundereToken with total supply very close to cap
        TsundereToken closeToCapToken = new TsundereToken(9990, 10000, 20);

        vm.prank(address(0x6));
        vm.expectRevert();
        closeToCapToken.claimFaucet();
    }
}
