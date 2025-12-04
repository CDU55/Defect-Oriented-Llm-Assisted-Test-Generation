
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager salaryManager;

    function setUp() public {
        salaryManager = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 2. State Configuration ---
        ForceSender force = new ForceSender{value: 1}();
        force.forceSend(address(salaryManager));
        
        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        salaryManager.cancelContract();
        assertEq(address(salaryManager).code.length, 0);
    }
}

contract ForceSender {
    constructor() payable {}

    function forceSend(address target) external {
        selfdestruct(payable(target));
    }
}
