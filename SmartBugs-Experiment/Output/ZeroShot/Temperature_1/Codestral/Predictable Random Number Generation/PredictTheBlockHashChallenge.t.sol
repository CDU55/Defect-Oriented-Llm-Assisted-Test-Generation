
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public challenge;

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint targetBlock) public {
        // --- 1. Constraints ---
        targetBlock = uint256(keccak256(abi.encode(targetBlock))) % 1000000000; // Avoid overflow
        vm.roll(targetBlock - 1);

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);
        challenge.lockInGuess{value: 1 ether}(bytes32(0));

        // --- 3. Replication & Assertion ---
        bytes32 predictedHash = blockhash(targetBlock);
        vm.roll(targetBlock);
        challenge.settle();

        assertEq(predictedHash, blockhash(targetBlock));
    }
}
