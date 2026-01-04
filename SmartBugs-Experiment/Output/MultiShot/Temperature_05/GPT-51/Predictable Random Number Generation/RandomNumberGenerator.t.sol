
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

        // Ensure future-ish timestamp and block number so assumptions are satisfiable
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);

        // max must be in a reasonable range and avoid division by zero in the contract
        vm.assume(max > 1 && max < type(uint256).max / 100);

        // Avoid overflow in salt * 100 / max and salt * block.number / (salt % 5)
        // salt is initialized to block.timestamp in the contract constructor, so we
        // approximate it here by constraining timestamp to a safe range.
        vm.assume(blockTimestamp < type(uint256).max / 1e9);
        vm.assume(blockNumber < type(uint256).max / 1e9);

        // --- 2. State Configuration ---

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---

        // The contract's salt is set once at deployment to the deployment timestamp.
        // We cannot read it directly (private), but for the purpose of demonstrating
        // predictability, we know it equals the deployment-time block.timestamp.
        // That timestamp is the timestamp at setUp(), which we can capture now.
        // However, since setUp has already run, we approximate by reading from
        // the creation block. In Foundry, deployment happens in the same tx as setUp,
        // so we can reconstruct salt as the timestamp at that moment.
        // To keep this deterministic, we redeploy a fresh instance here and capture
        // the salt-equivalent timestamp.

        // Deploy a fresh instance to know its salt (its constructor uses current timestamp)
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        uint256 deploymentTimestamp = block.timestamp;
        RandomNumberGenerator fresh = new RandomNumberGenerator();

        // Now move to the environment we want to test under
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        uint256 salt = deploymentTimestamp;

        uint256 x = salt * 100 / max;

        // Avoid division by zero in (salt % 5)
        // If salt % 5 == 0, the contract would revert; we skip such cases.
        vm.assume(salt % 5 != 0);

        uint256 y = salt * block.number / (salt % 5);
        uint256 seed = block.number / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expectedRandom = uint256((h / x)) % max + 1;

        uint256 actualRandom = fresh.random(max);

        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
