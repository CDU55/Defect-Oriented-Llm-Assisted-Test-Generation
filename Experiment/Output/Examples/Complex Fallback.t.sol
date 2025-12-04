// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ComplexFallback} from "../src/ComplexFallback.sol";

contract TestComplexFallbackComplexFallback is Test {
    
    ComplexFallback public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new ComplexFallback();
    }

    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        vm.deal(address(this), amount * 2);
        
        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        uint256 gasUsed = gasBefore - gasAfter;
                
        vm.assertTrue(gasUsed > 2300, "Gas used must be > 2300, making transfer() unsafe");
    }
}