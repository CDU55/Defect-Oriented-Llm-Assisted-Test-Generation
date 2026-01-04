
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        // --- 1. Constraints ---

        // Ensure we only move time/blocks forward
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);

        // salt is initialized once in constructor to constructor's block.timestamp,
        // which is less than or equal to our chosen future blockTimestamp.
        // We only need conditions to avoid division by zero and have valid blockhash.

        // blockhash only returns non-zero for the 256 most recent blocks.
        // The contract computes:
        //   uint256 seed = block.number / 3 + (salt % 300) + y;
        // where y depends on block.number and salt.
        // For predictability in the test, we don't require h != 0, we only
        // need the internal math not to revert (avoid division by zero and overflow).

        // Avoid max == 0 when calling random
        uint256 max = 100;
        vm.assume(max > 0);

        // --- 2. State Configuration ---

        // Manipulate block environment
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---

        // Recreate the internal logic of random(uint max)

        // salt is private but set once at deployment to the constructor's block.timestamp.
        // In Foundry, constructor ran at the original chain state before we warped/rolled,
        // so salt == block.timestamp at deployment. We can recover it indirectly:
        // Deploy a helper that exposes what the constructor timestamp was by checking
        // block.timestamp at deployment time; however, here we know the pattern:
        // salt is constant after deployment and independent of this test's later warps/rolls.
        //
        // In this controlled test, we leverage that salt was exactly the timestamp
        // at which setUp() executed. At that moment, block.timestamp was the current
        // value before we changed it. Foundry keeps that deterministic, so we can
        // snapshot it before warping/rolling:

        // To get that "deployment timestamp", we redeploy a helper here just to read block.timestamp.
        // But we cannot change the already deployed contract's salt, so instead we
        // track it explicitly using another deployment in the same environment.

        // In practice for this proof, we don't need the exact salt value from storage:
        // we can still compute the expected result symbolically because for a given
        // concrete blockchain state (salt, block.number, max), the expression is pure
        // and deterministic. In the context of this test, we know salt equals the
        // constructor timestamp, which was the timestamp at setUp() execution.
        //
        // Cache the deployment timestamp by re-reading the block from a prior snapshot.
        // We do this by assuming the constructor was deployed at timestamp 1 and roll
        // and warp back before setUp, which Foundry cannot do now.
        //
        // Instead, we read salt directly using vm.load (cheatcode) even though it's private.
        bytes32 saltSlot = bytes32(uint256(0)); // salt is first state variable at slot 0
        uint256 salt = uint256(vm.load(address(_contractUnderTest), saltSlot));

        uint256 x = salt * 100 / max;
        uint256 y = salt * block.number / (salt % 5);
        uint256 seed = block.number / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expectedRandom = uint256((h / x)) % max + 1;

        uint256 actualRandom = _contractUnderTest.random(max);

        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given controlled block state");
    }
}
