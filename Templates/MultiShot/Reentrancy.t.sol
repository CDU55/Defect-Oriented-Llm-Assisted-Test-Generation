// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested.
// [LLM_INSTRUCTION]: If you need to manipulate private state directly, import StdStorage: import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Prove that execution control can be hijacked to perform
// recursive calls, thereby breaking the intended atomicity of a sensitive method.
// ═══════════════════════════════════════════════════════════════════════════════

// [LLM_INSTRUCTION]: Name the contract 'TestReentrancy[ContractName]'
contract TestReentrancyTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup: using stdStorage for StdStorage;

    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Declare the contract under test and the malicious attacker contract.
    // ─────────────────────────────────────────────────────────────────────────

    // [LLM_INSTRUCTION]: Declare the contract under test variable (e.g. ReentrancySimple public _contractUnderTest)
    
    Attacker public _attacker;

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize the victim contract and the attacker contract.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If the constructor has parameters, use valid concrete values here (or setup variables).
        // 2. If the constructor is payable, use 'vm.deal(address(this), amount)' before 'new'.
        
        // _contractUnderTest = new ReentrancySimple();

        _attacker = new Attacker(address(_contractUnderTest));

        // ───────────────────────────────────────────────────────── [/Setup]
    }

    // [LLM_INSTRUCTION]: Add Fuzz/Symbolic arguments to the test function.
    // 1. 'attackVal': The value sent/withdrawn during the attack (e.g. amount).
    // 2. 'stateVal': Any value needed to configure the initial state (e.g. initial balance).
    // Example: function test_attackerCallsWithdrawMultipleTimes(uint256 attackVal, uint256 stateVal) public {
    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain Fuzz/Symbolic values and configure pre-conditions.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: Constrain the Fuzz/Symbolic values using 'vm.assume'.
        // WARNING: Avoid Integer Overflow. If attackVal is added to balances, ensure it doesn't wrap around.
        // WARNING: Avoid Balance Overflow. Do not use type(uint256).max for ETH amounts.
        // WARNING: Avoid Integer Underflow or Overflow during the attack scenario.
        // SUGGESTION: Use vm.assume to limit attackVal to a safe range.
        // SUGGESTION: Use type(uint128).max as a safe upper bound for balance math.
        // SUGGESTION: Limit the exploit to 1 initial call and 1 re-entrant call for simplicity.
        
        //vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // [LLM_INSTRUCTION]: Does the vulnerable function require specific state?
        // (e.g., specific balance, time passed, authorized user, boolean flag).

        // STRATEGY A: Public Methods (Preferred)
        // Call public setters or 'deposit' functions.
        // Example: _contractUnderTest.setVal(fuzzArg);

        // STRATEGY B: Storage Manipulation (For Private/Hard-to-reach State)
        // If the variable is private or requires complex logic to set, use 'vm.store' or 'stdstore'.
        // Example:
        // stdstore.target(address(_contractUnderTest)).sig("myVar()").checked_write(fuzzArg);
        
        // TIMING: If logic depends on time, use vm.warp(block.timestamp + 100);
        // ───────────────────────────────────────────────────────── [/Setup]
        // ─────────────────────────────────────────────────────────────────────
        // [Action] Fund contracts using vm.deal and trigger the attack sequence.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: Fund the contracts using vm.deal.
        // Use the fuzzed 'attackVal' to ensure sufficient balance.
        
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // B. Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        // The test contract needs funds because it sends 'attackVal' to the Attacker in the setup step below.
        // Without this, the test will fail with 'EvmError: OutOfFunds' if attackVal > default test balance.
        vm.deal(address(this), attackVal * 2);

        // [LLM_INSTRUCTION]: If the contract requires specific state (e.g. logic dependent on block.timestamp), set it here.
        
        // [LLM_INSTRUCTION]: Trigger the attack sequence.
        // Pass the Fuzz/Symbolic values to the setup and attack functions.
        // Note: The {value: attackVal} here draws from address(this), which is why we funded it above.
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
    // [LLM_INSTRUCTION]: Declare the victim contract variable with its specific type.
    // ReentrancySimple public _victim;
    
    // [Setup] Dedicated state variable to track the number of re-entries.
    uint256 public reentrancyCount;
    bool public exploitSucceeded;

    // [LLM_INSTRUCTION]: Declare state variables to store the Fuzz/Symbolic values.
    // We must store them because 'receive()' cannot accept arguments.
    // uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        // [LLM_INSTRUCTION]: Cast and store the victim address.
        // _victim = ReentrancySimple(victimAddress);
    }

    // ═══════════════════════════════════════════════════════════════ [/Setup]

    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Prepare the attacker's initial state (e.g., deposit into victim).
    // ─────────────────────────────────────────────────────────────────────────

    // [LLM_INSTRUCTION]: Update signature to accept Fuzz/Symbolic values.
    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        
        // [LLM_INSTRUCTION]: Perform preparation steps (e.g. deposit) using the Fuzz/Symbolic value.
        // Check: If the vulnerability requires a 'deposit' first, do it here.
        // _victim.deposit{value: val}();
    }

    // ───────────────────────────────────────────────────────────── [/Setup]

    // ─────────────────────────────────────────────────────────────────────────
    // [Action] Initiate the exploit by calling the victim's vulnerable function.
    // ─────────────────────────────────────────────────────────────────────────

    // [LLM_INSTRUCTION]: Update signature to accept Fuzz/Symbolic values.
    function attack(uint256 val) public {
        // [LLM_INSTRUCTION]: 1. Store the value for the re-entrant call if needed.
        // storedAttackVal = val;

        // [LLM_INSTRUCTION]: 2. Call the vulnerable function.
        // This initiates the external call that will trigger the callback.
        // _victim.withdraw(); (Or _victim.withdraw(val) if it takes args)

        // [Assertion] Set exploitSucceeded based on the success condition.
        // [LLM_INSTRUCTION]: The most common condition is reentrancyCount > 1.
        // However, you may also include additional contract-specific checks
        // (e.g., balance drained, state variables corrupted).
        // Example: if (reentrancyCount > 1) { exploitSucceeded = true; }
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
            // [LLM_INSTRUCTION]: Re-enter the victim's vulnerable method using the stored Fuzz/Symbolic value.
            // _victim.withdraw(); (Or _victim.withdraw(storedAttackVal))
        }
    }

    // ─────────────────────────────────────────────────── [/Callback Logic]
}