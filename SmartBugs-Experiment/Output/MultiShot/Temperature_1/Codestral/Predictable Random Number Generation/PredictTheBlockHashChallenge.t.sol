
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.deal(address(this), 1 ether);

        vm.assume(blockNumber >= block.number);

        address attacker = address(1);

        vm.startPrank(attacker);
        bytes32 guess = keccak256(abi.encode(blockNumber + 1));
        _contractUnderTest.lockInGuess{value: 1 ether}(guess);
        vm.stopPrank();

        vm.roll(blockNumber + 1);

        bytes32 expectedHash = blockhash(blockNumber + 1);

        vm.prank(attacker);
        _contractUnderTest.settle();

        assertEq(guess, expectedHash, "Randomness should be predictable given block state");
    }
}
