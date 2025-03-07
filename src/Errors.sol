// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error TransferToZeroAddress();
error TransferFromZeroAddress();
error TransferAmountZero();
error TransferAmountExceedsBalance(uint256 balance, uint256 amount);
error TransferAmountExceedsAllowance(uint256 allowance, uint256 amount);
error ApprovalToZeroAddress();
error ApprovalFromZeroAddress();
error ApprovalToSelf();
error ApprovalAmountZero();
error ApprovalAmountExceedsBalance(uint256 balance, uint256 amount);

error NotOwner();
error ContractPaused();
error AmountCannotBeZero();
error MintToZeroAddress();
error CapExceeded(uint256 currentSupply, uint256 mintAmount, uint256 cap);
error BurnAmountExceedsBalance(uint256 balance, uint256 burnAmount);
error AllowanceBelowZero(uint256 currentAllowance, uint256 subtractedValue);
error TransferOwnershipToZeroAddress();

error AlreadyClaimedFaucet();
