
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SalaryManager();
        vm.deal(address(_contractUnderTest), 10 ether);

        // Put the contract into a state where cancelContract's require passes:
        // _totalAllocated < address(this).balance
        // Owner sends some salary so _totalAllocated > 0 but still less than balance.
        vm.prank(address(this));
        _contractUnderTest.sendSalary{value: 1 ether}(address(0xBEEF));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the privileged owner (deployer of SalaryManager)
        vm.assume(caller != address(this));

        vm.prank(caller);
        _contractUnderTest.cancelContract();
    }
}
