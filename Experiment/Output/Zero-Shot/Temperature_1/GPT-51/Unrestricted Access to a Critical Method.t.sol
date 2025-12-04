
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

        // Exclude privileged role: the owner (deployer -> this test contract)
        vm.assume(caller != address(this));

        // Fund the contract so that balance > _totalAllocated (which is 0 by default)
        vm.deal(address(salaryManager), 1 ether);

        vm.prank(caller);
        salaryManager.cancelContract();

        // Optional side-effect check: contract code size should be zero after selfdestruct
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(sload(salaryManager.slot))
        }
        assertEq(codeSize, 0);
    }
}
