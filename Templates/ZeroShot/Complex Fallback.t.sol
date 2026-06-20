// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.
// [LLM_INSTRUCTION]: If you need to manipulate private state directly, import StdStorage: 
// import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Measure if the minimum execution path for mandatory callbacks
// (such as receive() or fallback()) exceeds the 2,300 gas stipend when storage
// is cold.
// ═══════════════════════════════════════════════════════════════════════════════

// [LLM_INSTRUCTION]: Name the contract 'TestComplexFallback[ContractName]'
contract TestComplexFallbackTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup: using stdStorage for StdStorage;

    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Declare the contract under test variable.
    // ─────────────────────────────────────────────────────────────────────────

    // [LLM_INSTRUCTION]: Declare the contract under test variable

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize a fresh test environment where no previous calls
        // have been made to the contract, ensuring all state variables are in
        // a cold state (maximizing SLOAD/SSTORE gas costs).
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If constructor parameters are needed, use concrete valid values.
        // 2. If payable, use vm.deal(address(this), amount) before deployment.
        
        // ───────────────────────────────────────────────────────── [/Setup]
    }

    // [LLM_INSTRUCTION]: Add Fuzz/Symbolic arguments.
    // 'amount': The value transferred to trigger the fallback.
    // 'stateVal': Any value needed to configure the state (optional).
    // Example: function test_highlightGasNeededIsOver2300(uint256 amount) public {
    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain fuzz/symbolic values and configure pre-conditions.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: Constrain the Fuzz/Symbolic values.
        // WARNING: Avoid Integer/Balance Overflow.
         vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        // [LLM_INSTRUCTION]: FUNDING
        // A. Create and Fund a dedicated Sender address
         address sender = makeAddr("sender");
         vm.deal(sender, amount * 2);
        //
        // B. Fund the Test Contract (Safety Net)
         vm.deal(address(this), amount * 2);

        // ───────────────────────────────────────────────────────── [/Setup]

        // ─────────────────────────────────────────────────────────────────────
        // [Measurement] Identify paths where the fallback reads multiple state
        // variables. Each cold SLOAD consumes 2,100 gas, rapidly exhausting
        // the 2,300 stipend.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: STATE VARIABLES
        // Does the fallback logic depend on specific state to be expensive?
        // (e.g. executing a loop only when 'isProcessing' is true).
        
        // STRATEGY A: Public Methods (Preferred)
        // Call public setters.

        // STRATEGY B: Storage Manipulation
        // Use vm.store or stdstore to modify state.

        // ────────────────────────────────────────────────────── [/Measurement]

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Two-probe materialization of dGas(pi) > 2300, reproducing
        // exactly what transfer()/send() do — they forward only the 2300 stipend.
        //   Probe 1 (stipend-bounded): gas: 0. Since value > 0, the EVM adds
        //     exactly the 2300 stipend, so the callee receives 2300 gas. A callback
        //     whose path costs > 2300 runs out of gas -> the call returns false.
        //   Probe 2 (unbounded): forward all gas -> a well-formed payable callback
        //     succeeds. Each probe runs against a FRESH, cold instance.
        // ─────────────────────────────────────────────────────────────────────
        
        // [LLM_INSTRUCTION]: Probe 1 — stipend-bounded call on the cold setUp instance.
         vm.prank(sender);
         (bool okStipend, ) = address(_contractUnderTest).call{value: amount, gas: 0}("");

        // [LLM_INSTRUCTION]: Deploy a SECOND fresh instance identical to setUp (re-apply
        // any expensive-state config) so Probe 2 also starts from cold storage, then
        // issue the unbounded call.
        // Example:
        // ComplexFallback freshInstance = new ComplexFallback();
         vm.prank(sender);
         (bool okUnbounded, ) = address(freshInstance).call{value: amount}("");

        // ─────────────────────────────────────────────────────────── [/Action]

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] dGas(pi) > 2300  <=>  the unbounded call SUCCEEDS and the
        // stipend-bounded call REVERTS. If both succeed, the callback fits within
        // the 2300 stipend and the contract is NOT gas-locked (test fails).
        // ─────────────────────────────────────────────────────────────────────

         assertTrue(okUnbounded && !okStipend, "Callback fits within the 2300 stipend: not gas-locked");

        // ──────────────────────────────────────────────────── [/Assertion]
    }
}