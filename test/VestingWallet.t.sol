// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {TaraChatToken} from "../src/Token.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingWalletTest is Test {
    TaraChatToken token;

    // Vesting wallets addresses
    address ecosystemWallet;
    address teamGrowthWallet1;
    address teamGrowthWallet2;
    address communityWallet;
    address marketingWallet;

    // Beneficiary accounts (replace with actual private keys if needed)
    address beneficiary1 = vm.addr(1); // Dummy address for testing purposes
    address beneficiary2 = vm.addr(2); // Dummy address for testing purposes

    function setUp() public {
        // Deploy the TaraChatToken contract with the deployer as the initial owner
        token = new TaraChatToken(address(this));

        // Retrieve vesting wallet addresses via getter functions
        ecosystemWallet = token.ecosystemDevelopmentVestingWallet();
        teamGrowthWallet1 = token.teamGrowthVestingWallet1();
        teamGrowthWallet2 = token.teamGrowthVestingWallet2();
        communityWallet = token.communityEngagementVestingWallet();
        marketingWallet = token.marketingPromotionVestingWallet();
    }

    function testVestingWalletBalances() public view {
        // Verify the initial balances in the vesting wallets
        assertEq(
            token.balanceOf(ecosystemWallet),
            token.ecosystemDevelopment()
        );
        assertEq(token.balanceOf(teamGrowthWallet1), token.teamGrowth() / 2);
        assertEq(token.balanceOf(teamGrowthWallet2), token.teamGrowth() / 2);
        assertEq(token.balanceOf(communityWallet), token.communityEngagement());
        assertEq(token.balanceOf(marketingWallet), token.marketingPromotion());
    }

    function testVestingRelease() public {
        // Simulate time passing (2 months)
        vm.warp(block.timestamp + 60 days);

        // Release tokens from the vesting wallets
        VestingWallet(payable(ecosystemWallet)).release(address(token));
        VestingWallet(payable(teamGrowthWallet1)).release(address(token));
        VestingWallet(payable(teamGrowthWallet2)).release(address(token));
        VestingWallet(payable(communityWallet)).release(address(token));
        VestingWallet(payable(marketingWallet)).release(address(token));

        // Check if tokens were released correctly (some tokens should still be vesting)
        uint256 ecosystemReleased = VestingWallet(payable(ecosystemWallet))
            .released(address(token));
        uint256 teamGrowthReleased1 = VestingWallet(payable(teamGrowthWallet1))
            .released(address(token));
        uint256 teamGrowthReleased2 = VestingWallet(payable(teamGrowthWallet2))
            .released(address(token));
        uint256 communityReleased = VestingWallet(payable(communityWallet))
            .released(address(token));
        uint256 marketingReleased = VestingWallet(payable(marketingWallet))
            .released(address(token));

        assertGt(ecosystemReleased, 0);
        assertGt(teamGrowthReleased1, 0);
        assertGt(teamGrowthReleased2, 0);
        assertGt(communityReleased, 0);
        assertGt(marketingReleased, 0);
    }

    function testBeneficiaryCanWithdraw() public {
        // Simulate time passing to fully vest the tokens
        vm.warp(block.timestamp + 360 days);

        // Check the balance before releasing
        uint256 balanceBefore = token.balanceOf(
            0xaDcB2f54F652BFD7Ac1d7D7b12213b4519F0265D
        );

        // Set the VM to act as the real beneficiary
        vm.prank(0xaDcB2f54F652BFD7Ac1d7D7b12213b4519F0265D);

        // Release tokens from one of the vesting wallets
        VestingWallet(payable(teamGrowthWallet1)).release(address(token));

        // Check the balance after releasing
        uint256 balanceAfter = token.balanceOf(
            0xaDcB2f54F652BFD7Ac1d7D7b12213b4519F0265D
        );

        // Assert that the beneficiary's balance has increased
        assertGt(balanceAfter, balanceBefore);
    }
}
