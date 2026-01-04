
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {
    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber, uint256 max) public {
        // --- 1. Constraints ---

        // Ensure forward-only movement of time and block number
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);

        // max must be > 1 to make randomness meaningful and avoid division by zero
        vm.assume(max > 1);

        // Avoid overflow in internal multiplications/divisions:
        // salt = block.timestamp, so constrain timestamp to a reasonable range
        vm.assume(blockTimestamp < type(uint64).max);
        vm.assume(blockNumber < type(uint64).max);

        // --- 2. State Configuration ---

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---

        // The contract uses:
        //   uint256 salt = block.timestamp; (set at deployment)
        // In this test, we know deployment happened in setUp() at the original block.timestamp.
        // To make the test deterministic, we read the salt indirectly by reproducing
        // the same logic the contract used at deployment: salt = deploymentTimestamp.
        //
        // However, since `salt` is private and set only once at deployment, and we
        // cannot read it directly, we instead reconstruct the expected output
        // using the same formula but with the known deployment timestamp.
        //
        // We know that at deployment, block.timestamp was the timestamp at setUp().
        // Capture that value by redeploying a reference contract in a controlled env.

        // Deploy a reference contract to capture its salt (deployment timestamp)
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        RandomNumberGenerator ref = new RandomNumberGenerator();

        // Now, at this point, ref.salt == current block.timestamp.
        // We will use this same timestamp as the salt for our prediction of
        // _contractUnderTest's randomness, because both contracts use the same
        // deterministic formula based solely on block state at call time and
        // their immutable salt set at deployment.
        //
        // For the purpose of demonstrating predictability, we call random on
        // the reference contract and on the contract under test under the same
        // block conditions and show they are equal to our local computation.

        uint256 salt = block.timestamp;

        // Restore the caller-controlled environment for the actual test call
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // Reproduce the contract's logic locally
        uint256 x = salt * 100 / max;
        // Avoid division by zero in (salt % 5)
        // If salt % 5 == 0, the contract would revert; avoid that path.
        vm.assume(salt % 5 != 0);
        uint256 y = salt * block.number / (salt % 5);
        uint256 seed = block.number / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expectedRandom = uint256((h / x)) % max + 1;

        uint256 actualRandom = _contractUnderTest.random(max);

        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
