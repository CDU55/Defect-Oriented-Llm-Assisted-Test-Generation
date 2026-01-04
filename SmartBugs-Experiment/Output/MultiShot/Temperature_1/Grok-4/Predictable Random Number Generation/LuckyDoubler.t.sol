
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber > 0);
        
        vm.roll(blockNumber);
        
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        
        vm.prank(alice);
        payable(_contractUnderTest).transfer(1 ether);
        
        uint256 constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 max = 2;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 expectedRandom = (hashVal / factor) % max;
        
        vm.prank(bob);
        payable(_contractUnderTest).transfer(1 ether);
        
        (, , bool paid0, ) = _contractUnderTest.entryDetails(0);
        (, , bool paid1, ) = _contractUnderTest.entryDetails(1);
        
        uint256 actualRandom;
        if (paid0 && !paid1) actualRandom = 0;
        else if (!paid0 && paid1) actualRandom = 1;
        else fail();
        
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
