// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "../src/Token.sol";

contract StakingTest is Test {
    TaraChatToken stakingToken;
    TaraChatToken rewardsToken;
    Staking staking;

    function setUp() public {
        stakingToken = new TaraChatToken();
        rewardsToken = new TaraChatToken();

        // Assuming the deployer (address(this)) has the required permissions automatically

        staking = new Staking(address(stakingToken), address(rewardsToken));

        stakingToken.mint(address(this), 100 * 10 ** 18);
        rewardsToken.mint(address(staking), 100 * 10 ** 18);
    }

    function testStake() public {
        stakingToken.approve(address(staking), 100 * 10 ** 18);
        staking.stake(50 * 10 ** 18);
        assertEq(stakingToken.balanceOf(address(this)), 50 * 10 ** 18);
    }

    function testWithdraw() public {
        stakingToken.approve(address(staking), 100 * 10 ** 18);
        staking.stake(50 * 10 ** 18);
        staking.withdraw(50 * 10 ** 18);
        assertEq(stakingToken.balanceOf(address(this)), 100 * 10 ** 18);
    }
}
