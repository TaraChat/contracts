// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DiscreteStakingRewards is Ownable {
    IERC20 public immutable token;

    struct UnstakeRequest {
        uint256 amount;
        uint256 unstakeTimestamp;
        bool isActive;
    }

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    mapping(address => UnstakeRequest) public unstakeRequests;

    uint256 private constant MULTIPLIER = 1e18;
    uint256 private rewardIndex;
    mapping(address => uint256) private rewardIndexOf;
    mapping(address => uint256) private earned;

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    function updateRewardIndex(uint256 reward) external {
        token.transferFrom(msg.sender, address(this), reward);
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }

    function _calculateRewards(address account) private view returns (uint256) {
        uint256 shares = balanceOf[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    function calculateRewardsEarned(
        address account
    ) external view returns (uint256) {
        if (unstakeRequests[account].isActive) {
            // If unstaking is active, do not calculate rewards during the unstaking period
            return earned[account];
        }
        return earned[account] + _calculateRewards(account);
    }

    function _updateRewards(address account) private {
        if (!unstakeRequests[account].isActive) {
            earned[account] += _calculateRewards(account);
        }
        rewardIndexOf[account] = rewardIndex;
    }

    function stake(uint256 amount) external {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        // This will succeed if the user has approved the Staking contract to transfer the tokens
        token.transferFrom(msg.sender, address(this), amount);

        // Cancel any active unstake request if the user stakes more tokens
        if (unstakeRequests[msg.sender].isActive) {
            unstakeRequests[msg.sender] = UnstakeRequest(0, 0, false);
        }
    }

    function requestUnstake(uint256 amount) external {
        require(
            balanceOf[msg.sender] >= amount,
            "Insufficient balance to unstake"
        );
        _updateRewards(msg.sender);

        // Record the unstake request
        unstakeRequests[msg.sender] = UnstakeRequest(
            amount,
            block.timestamp,
            true
        );

        // Reduce staked balance immediately
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
    }

    function cancelUnstake() external {
        require(
            unstakeRequests[msg.sender].isActive,
            "No active unstake request to cancel"
        );

        // Restore the staked balance
        balanceOf[msg.sender] += unstakeRequests[msg.sender].amount;
        totalSupply += unstakeRequests[msg.sender].amount;

        // Cancel the unstake request
        unstakeRequests[msg.sender] = UnstakeRequest(0, 0, false);
    }

    function finalizeUnstake() external {
        UnstakeRequest memory request = unstakeRequests[msg.sender];
        require(request.isActive, "No active unstake request");
        require(
            block.timestamp >= request.unstakeTimestamp + 30 days,
            "Unstaking period not yet completed"
        );

        // Complete the unstake by transferring tokens back to the user
        token.transfer(msg.sender, request.amount);

        // Clear the unstake request
        unstakeRequests[msg.sender] = UnstakeRequest(0, 0, false);
    }

    function claim() external returns (uint256) {
        _updateRewards(msg.sender);

        uint256 reward = earned[msg.sender];
        if (reward > 0) {
            earned[msg.sender] = 0;
            token.transfer(msg.sender, reward);
        }

        return reward;
    }
}
