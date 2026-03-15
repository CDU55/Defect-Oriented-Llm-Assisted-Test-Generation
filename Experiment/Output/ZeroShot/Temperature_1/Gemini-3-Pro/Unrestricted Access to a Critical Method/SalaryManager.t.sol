// Generation Time: 39,72s
// Input Tokens: 2492
// Output Tokens: 610
// Reasoning Tokens: 3253


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Verify if critical methods are properly protected by ensuring
// that unauthorized addresses cannot reach or modify a sensitive contract state.
// ═══════════════════════════════════════════════════════════════════════════════

contract TestAccessControlSalaryManager is Test {
    
    SalaryManager salaryManager;

    function setUp() public {
        salaryManager = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Fuzzing] Declare a fuzzed/symbolic address (unauthorizedUser) and
        // constrain it using vm.assume to exclude all privileged addresses.
        // ─────────────────────────────────────────────────────────────────────

        vm.assume(caller != address(this)); // Exclude Owner (Test Contract)
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Configure any required pre-conditions.
        // ─────────────────────────────────────────────────────────────────────

        // The target function 'cancelContract' requires (_totalAllocated < address(this).balance).
        // _totalAllocated starts at 0. We inject ETH via vm.deal to satisfy the condition (0 < 1 ether).
        uint256 contractBalance = 1 ether;
        vm.deal(address(salaryManager), contractBalance);
        
        uint256 preBalance = caller.balance;

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Use vm.prank(unauthorizedUser) to simulate the transaction.
        // ─────────────────────────────────────────────────────────────────────

        vm.prank(caller);
        salaryManager.cancelContract();

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Assert that the sensitive method executed successfully.
        // ─────────────────────────────────────────────────────────────────────

        // If the call succeeded, the caller should have received the contract's balance via selfdestruct.
        assertEq(caller.balance, preBalance + contractBalance, "Unauthorized caller should receive funds via cancelContract");
    }
}
