// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {DiscreteStakingRewards} from "../src/Staking.sol";
import {TaraChatToken} from "../src/Token.sol";

contract StakingTest is Test {
    TaraChatToken public token;
    DiscreteStakingRewards public staking;

    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);

    function setUp() public {
        // Deploy the token and staking contracts with the correct owner
        vm.startPrank(owner);
        token = new TaraChatToken(owner);
        staking = new DiscreteStakingRewards(address(token));
        vm.stopPrank();

        // Mint tokens to users for staking as the owner
        vm.startPrank(owner);
        token.mint(user1, 1000e18);
        token.mint(user2, 1000e18);
        vm.stopPrank();

        // Approve the staking contract to spend user1 and user2's tokens
        vm.startPrank(user1);
        token.approve(address(staking), 1000e18);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), 1000e18);
        vm.stopPrank();
    }

    function testStake() public {
        vm.prank(user1);
        staking.stake(100e18);

        // Check balances after staking
        assertEq(staking.balanceOf(user1), 100e18);
        assertEq(staking.totalSupply(), 100e18);
        assertEq(token.balanceOf(user1), 900e18);
        assertEq(token.balanceOf(address(staking)), 100e18);
    }

    function testUnstakeRequest() public {
        vm.prank(user1);
        staking.stake(200e18);

        vm.prank(user1);
        staking.requestUnstake(100e18);

        // Check balances after requesting unstake
        assertEq(staking.balanceOf(user1), 100e18); // 200 staked - 100 requested to unstake
        assertEq(staking.totalSupply(), 100e18); // Total supply reduced
        assertEq(token.balanceOf(user1), 800e18); // User should still have 800 tokens
    }

    function testCancelUnstake() public {
        vm.prank(user1);
        staking.stake(200e18);

        vm.prank(user1);
        staking.requestUnstake(100e18);

        vm.prank(user1);
        staking.cancelUnstake();

        // Check balances after canceling unstake
        assertEq(staking.balanceOf(user1), 200e18); // 200 staked
        assertEq(staking.totalSupply(), 200e18); // Total supply restored
        assertEq(token.balanceOf(user1), 800e18); // User still has 800 tokens
    }

    function testFinalizeUnstake() public {
        vm.prank(user1);
        staking.stake(200e18);

        vm.prank(user1);
        staking.requestUnstake(100e18);

        // Fast forward time by 30 days
        vm.warp(block.timestamp + 30 days);

        vm.prank(user1);
        staking.finalizeUnstake();

        // Check balances after finalizing unstake
        assertEq(staking.balanceOf(user1), 100e18); // Only 100 still staked
        assertEq(staking.totalSupply(), 100e18); // Total supply reduced
        assertEq(token.balanceOf(user1), 900e18); // User got 100 tokens back
    }

    function testClaimRewards() public {
        // User1 stakes 100 tokens
        vm.prank(user1);
        staking.stake(100e18);

        // Owner mints 50 tokens for rewards
        vm.prank(owner);
        token.mint(owner, 50e18);

        // Owner approves the staking contract to spend 50 tokens
        vm.prank(owner);
        token.approve(address(staking), 50e18);

        // Transfer tokens to staking contract
        vm.prank(owner);
        token.transfer(address(staking), 50e18);

        // Verify the staking contract's balance before updating the reward index
        assertEq(
            token.balanceOf(address(staking)),
            150e18,
            "Staking contract should have 150 tokens (100 staked + 50 rewards)"
        );

        // Update the reward index
        vm.prank(owner);
        staking.updateRewardIndex(50e18);

        // User1 claims rewards
        vm.prank(user1);
        uint256 reward = staking.claim();

        // Check reward balances after claiming
        assertEq(reward, 50e18); // User1 should receive 50 tokens as rewards
        assertEq(token.balanceOf(user1), 950e18); // 900 + 50 rewards
    }

    function testNoRewardsDuringUnstaking() public {
        uint256 initialRewardAmount = token.balanceOf(address(staking));

        // User1 stakes 100 tokens
        vm.prank(user1);
        staking.stake(100e18);

        // Owner mints and transfers 50 tokens to the staking contract for rewards
        vm.prank(owner);
        token.mint(owner, 50e18);

        // Approve a sufficient amount for staking contract to use
        vm.prank(owner);
        token.approve(address(staking), 50e18);

        // Transfer tokens to staking contract
        vm.prank(owner);
        token.transfer(address(staking), 50e18);

        // Verify the staking contract's balance before updating the reward index
        assertEq(
            token.balanceOf(address(staking)),
            initialRewardAmount + 100e18 + 50e18,
            "Staking contract should have 150 tokens (100 staked + 50 rewards)"
        );

        // Update the reward index
        vm.prank(owner);
        staking.updateRewardIndex(50e18);

        // User1 requests to unstake 50 tokens (half of their staked amount)
        vm.prank(user1);
        staking.requestUnstake(50e18);

        // User1 tries to claim rewards during unstaking period
        uint256 reward = staking.claim();

        // Check that no rewards are given during unstaking
        assertEq(
            reward,
            0,
            "No rewards should be distributed during the unstaking period"
        );

        // Verify no rewards were mistakenly added during the unstaking period
        assertEq(
            token.balanceOf(user1),
            900e18,
            "User1's balance should remain 900 after the unstaking request"
        );

        // Finalize the unstake after 30 days
        vm.warp(block.timestamp + 31 days);
        vm.prank(user1);
        staking.finalizeUnstake();

        // Verify the final state
        assertEq(staking.balanceOf(user1), 50e18); // 50 tokens should still be staked
        assertEq(token.balanceOf(user1), 950e18); // User1 should have gotten their 50 unstaked tokens back
    }
}
