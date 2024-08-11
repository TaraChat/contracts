// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Governor.sol";
import "../src/Token.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernorTest is Test {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    TaraChatGovernor public governor;
    TaraChatToken public token;
    TimelockController public timelock;

    address public deployer = address(0x123);
    address public voter1 = address(0x456);
    address public voter2 = address(0x789);
    address public targetContract = address(0x12345678); // Mock contract for testing

    function setUp() public {
        vm.startPrank(deployer);

        token = new TaraChatToken(deployer);
        // Declare and initialize arrays correctly
        address[] memory proposers = new address[](1);
        proposers[0] = deployer;

        address[] memory executors = new address[](1);
        executors[0] = deployer;

        timelock = new TimelockController(
            1 days,
            proposers,
            executors,
            deployer
        );

        // Allocate tokens to voters
        token.mint(deployer, 51_000_000e18);
        token.mint(voter1, 850_000_000e18);
        token.mint(voter2, 51_000_000e18);
        vm.warp(block.timestamp + 1);
        token.delegate(voter2);
        governor = new TaraChatGovernor(token, timelock);
        vm.stopPrank();
    }

    function testProposeAndVote() public {
        vm.startPrank(voter1);
        // Delegate votes to self
        token.delegate(voter1);

        // Ensure that delegation is recognized by moving forward in time
        vm.warp(block.timestamp + 1);
        // Declare and initialize variables correctly
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = targetContract;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("someFunction()");

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Proposal: Call someFunction"
        );

        assertEq(
            uint(governor.state(proposalId)),
            uint(IGovernor.ProposalState.Pending)
        );

        // Move forward in time to start voting
        vm.warp(block.timestamp + governor.votingDelay() + 1);

        assertEq(
            uint(governor.state(proposalId)),
            uint(IGovernor.ProposalState.Active)
        );

        // Cast vote
        governor.castVote(proposalId, 1); // 1 = For

        vm.stopPrank();

        // Check proposal state after voting
        vm.startPrank(voter2);
        vm.warp(block.timestamp + governor.votingPeriod() + 1);

        uint proposalState = uint(governor.state(proposalId));
        bool isSucceededOrDefeated = (proposalState ==
            uint(IGovernor.ProposalState.Succeeded)) ||
            (proposalState == uint(IGovernor.ProposalState.Defeated));

        assertTrue(
            isSucceededOrDefeated,
            "Proposal state is neither Succeeded nor Defeated"
        );

        vm.stopPrank();
    }

    function testQueueAndExecute() public {
        vm.startPrank(voter1);

        // Delegate votes to self
        token.delegate(voter1);

        // Ensure that delegation is recognized by moving forward in time
        vm.warp(block.timestamp + 1);

        // Declare and initialize variables correctly
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = targetContract;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("someFunction()");

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Proposal: Call someFunction"
        );

        // Move forward in time to start voting
        vm.warp(block.timestamp + governor.votingDelay() + 1);

        // Cast vote
        governor.castVote(proposalId, 1); // 1 = For

        // Fast forward to end of voting period
        vm.warp(block.timestamp + governor.votingPeriod() + 1);

        // Check if the proposal succeeded before queuing
        uint proposalState = uint(governor.state(proposalId));
        bool isSucceeded = (proposalState ==
            uint(IGovernor.ProposalState.Succeeded));

        assertTrue(isSucceeded, "Proposal did not succeed, cannot queue");

        if (isSucceeded) {
            // Queue the proposal
            governor.queue(
                targets,
                values,
                calldatas,
                keccak256(abi.encodePacked("Proposal: Call someFunction"))
            );

            assertEq(
                uint(governor.state(proposalId)),
                uint(IGovernor.ProposalState.Queued)
            );

            // Fast forward to execute the proposal
            vm.warp(block.timestamp + 2 days);

            governor.execute(
                targets,
                values,
                calldatas,
                keccak256(abi.encodePacked("Proposal: Call someFunction"))
            );

            assertEq(
                uint(governor.state(proposalId)),
                uint(IGovernor.ProposalState.Executed)
            );
        }

        vm.stopPrank();
    }
}
