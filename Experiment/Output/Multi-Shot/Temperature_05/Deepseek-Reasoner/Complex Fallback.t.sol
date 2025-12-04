
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract TestComplexFallbackCrowdfund is Test {
    Crowdfund public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Crowdfund();
    }

    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);
        vm.deal(address(this), amount * 2);

        uint256 gasBefore = gasleft();
        
        vm.prank(sender);
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");
        require(success, "Call failed");
        
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assert(gasUsed > 2300);
    }
}
