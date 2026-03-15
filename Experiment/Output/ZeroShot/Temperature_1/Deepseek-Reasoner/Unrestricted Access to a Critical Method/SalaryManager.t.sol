// Generation Time: 88,31s
// Input Tokens: 2515
// Output Tokens: 282
// Reasoning Tokens: 3510


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestAccessControlSalaryManager is Test {
    using stdStorage for StdStorage;

    SalaryManager public salaryManager;

    function setUp() public {
        salaryManager = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != address(salaryManager.owner()));

        uint256 contractBalance = 2 ether;
        vm.deal(address(salaryManager), contractBalance);

        stdstore.target(address(salaryManager)).sig("_totalAllocated()").checked_write(0);

        vm.prank(caller);
        salaryManager.cancelContract();
    }
}
