
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.deal(address(_contractUnderTest), 1 ether);

        vm.prank(caller);

        _contractUnderTest.cancelContract();

        assertTrue(address(_contractUnderTest).code.length == 0);
    }
}
