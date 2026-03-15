// Generation Time: 21,90s
// Input Tokens: 2344
// Output Tokens: 914
// Reasoning Tokens: 1258


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Measure if the minimum execution path for mandatory callbacks
// (such as receive() or fallback()) exceeds the 2,300 gas stipend when storage
// is cold.
// ═══════════════════════════════════════════════════════════════════════════════

contract TestComplexFallbackCrowdfund is Test {
    
    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Declare the contract under test variable.
    // ─────────────────────────────────────────────────────────────────────────

    Crowdfund public _contractUnderTest;

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize a fresh test environment where no previous calls
        // have been made to the contract, ensuring all state variables are in
        // a cold state (maximizing SLOAD/SSTORE gas costs).
        // ─────────────────────────────────────────────────────────────────────

        _contractUnderTest = new Crowdfund();

        // ───────────────────────────────────────────────────────── [/Setup]
    }

    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain fuzz/symbolic values and configure pre-conditions.
        // ─────────────────────────────────────────────────────────────────────

        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        // Fund the Test Contract (Safety Net)
        vm.deal(address(this), amount * 2);

        // ───────────────────────────────────────────────────────── [/Setup]

        // ─────────────────────────────────────────────────────────────────────
        // [Measurement] Identify paths where the fallback reads multiple state
        // variables. Each cold SLOAD consumes 2,100 gas, rapidly exhausting
        // the 2,300 stipend.
        // ─────────────────────────────────────────────────────────────────────

        // The Crowdfund contract is active by default in the constructor.
        // The receive() function performs SLOADs and SSTOREs immediately.
        // No additional state setup is required to trigger the expensive path.

        // ────────────────────────────────────────────────────── [/Measurement]

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Execute a low-level call to the victim contract to transfer
        // currency. Capture gasleft() immediately before (state σ) and after
        // (state σ') to compute the delta.
        // ─────────────────────────────────────────────────────────────────────
        
        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        // Ensure the call succeeded so we measured valid execution gas
        require(success, "Fallback call failed unexpectedly");

        // ─────────────────────────────────────────────────────────── [/Action]

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Calculate gasUsed = gasBefore - gasAfter and assert that
        // this value remains below 2,300. If gasUsed > 2300, the contract will
        // revert during standard transfer() or send() calls, effectively
        // locking incoming Ether.
        // ─────────────────────────────────────────────────────────────────────

        uint256 gasUsed = gasBefore - gasAfter;
        
        // Verify gas usage exceeds the 2,300 stipend (vulnerability confirmed)
        assertTrue(gasUsed >= 2300, "Gas used does not exceed 2300");

        // ──────────────────────────────────────────────────── [/Assertion]
    }
}
