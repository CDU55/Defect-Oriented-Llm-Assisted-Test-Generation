// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {BadRandomNumberGen} from "../src/BadRandomNumberGen.sol"; 

contract TestBadRandomNumberGen is Test {

    BadRandomNumberGen public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new BadRandomNumberGen();

        vm.deal(address(_contractUnderTest), 10 ether);

        vm.deal(address(this), 10 ether);
    }

    function test_highlightPredictableRandomValue(
        uint256 blockTimestamp, 
        uint256 blockNumber
    ) public {
        
        uint256 cooldown = _contractUnderTest.COOLDOWN();

        vm.assume(blockTimestamp >= block.timestamp + cooldown);
        
        vm.assume(blockNumber >= block.number);

        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp, 
                    blockNumber, 
                    address(this) 
                )
            )
        );

        uint256 expectedRandom = seed % 100;
        
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);

        (, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        
        assertEq(wins, 1, "Randomness should be predictable given block state");
    }

    receive() external payable {}
}