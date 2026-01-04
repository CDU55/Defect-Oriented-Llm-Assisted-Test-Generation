
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        vm.assume(blockNumber >= block.number);
        
        vm.roll(blockNumber);
        
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        vm.prank(user1);
        (bool success, ) = address(_contractUnderTest).call{value: 1 ether}("");
        assert(success);
        
        uint256 constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint max = 2;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 expectedIndex = uint256((hashVal / factor)) % max;
        
        uint256 user1BalBefore = user1.balance;
        uint256 user2BalBefore = user2.balance;
        
        vm.prank(user2);
        (success, ) = address(_contractUnderTest).call{value: 1 ether}("");
        assert(success);
        
        uint256 payout = (1 ether * 125) / 100;
        
        if (expectedIndex == 0) {
            assertEq(user1.balance, user1BalBefore + payout);
            assertEq(user2.balance, user2BalBefore - 1 ether);
        } else {
            assertEq(user2.balance, user2BalBefore - 1 ether + payout);
            assertEq(user1.balance, user1BalBefore);
        }
    }
}
