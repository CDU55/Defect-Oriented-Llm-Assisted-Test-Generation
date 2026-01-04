
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler private luckyDoubler;

    function setUp() public {
        luckyDoubler = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, bytes32 blockHash) public {
        
        uint256 minBlockNumber = 256;
        vm.assume(blockNumber >= minBlockNumber && blockNumber <= type(uint256).max - 100);
        
        uint256 startingBlock = blockNumber - 1;
        vm.roll(startingBlock);
        vm.blockHash(startingBlock, blockHash);
        
        address user1 = address(0x123);
        address user2 = address(0x456);
        deal(user1, 10 ether);
        deal(user2, 10 ether);
        
        vm.prank(user1);
        (bool success1, ) = address(luckyDoubler).call{value: 1 ether}("");
        require(success1, "First deposit failed");
        
        vm.prank(user2);
        (bool success2, ) = address(luckyDoubler).call{value: 1 ether}("");
        require(success2, "Second deposit failed");
        
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 randFactor = factor * 100 / 2;
        uint256 hashVal = uint256(blockHash);
        uint256 expectedIndex = (hashVal / randFactor) % 2;
        
        vm.roll(blockNumber);
        vm.blockHash(blockNumber - 1, blockHash);
        
        address user3 = address(0x789);
        deal(user3, 10 ether);
        vm.prank(user3);
        (bool success3, ) = address(luckyDoubler).call{value: 1 ether}("");
        require(success3, "Third deposit failed");
        
        (uint256 deposits1, uint256 payouts1, ) = luckyDoubler.userStats(user1);
        (uint256 deposits2, uint256 payouts2, ) = luckyDoubler.userStats(user2);
        
        if (expectedIndex == 0) {
            assertEq(payouts1, 1, "User1 should have received payout");
            assertEq(payouts2, 0, "User2 should not have received payout");
        } else {
            assertEq(payouts1, 0, "User1 should not have received payout");
            assertEq(payouts2, 1, "User2 should have received payout");
        }
    }
}
