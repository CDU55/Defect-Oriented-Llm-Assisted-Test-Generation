
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);
        
        vm.roll(blockNumber);
        
        bool expectedWon = (blockNumber % 2) == 0;
        
        uint256 initialContractBalance = address(_contractUnderTest).balance;
        uint256 betAmount = 1 ether;
        
        vm.deal(address(this), betAmount);
        
        _contractUnderTest.makeBet{value: betAmount}();
        
        uint256 finalContractBalance = address(_contractUnderTest).balance;
        
        if (expectedWon) {
            assertEq(finalContractBalance, initialContractBalance, "Contract should not keep funds when bet wins");
        } else {
            assertEq(finalContractBalance, initialContractBalance + betAmount, "Contract should keep funds when bet loses");
        }
    }
}
