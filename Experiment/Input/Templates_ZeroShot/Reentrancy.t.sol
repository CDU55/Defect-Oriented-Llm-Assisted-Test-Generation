// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested.
// [LLM_INSTRUCTION]: If you need to manipulate private state directly, import StdStorage: import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.

// [LLM_INSTRUCTION]: Name the contract 'TestReentrancy[ContractName]'
contract TestReentrancyTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup: using stdStorage for StdStorage;

    // [LLM_INSTRUCTION]: Declare the contract under test variable
    
    Attacker public _attacker;

    function setUp() public {
        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If constructor parameters are needed, use concrete valid values.
        // 2. If payable, attach currency to deployment.
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    // [LLM_INSTRUCTION]: Add Fuzz/Symbolic arguments to the test function.
    // 1. 'attackVal': The value sent/withdrawn during the attack.
    // 2. 'stateVal': Any value needed to configure the initial state.
    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // [LLM_INSTRUCTION]: Constrain the Fuzz/Symbolic values using 'vm.assume'.
        // WARNING: Avoid Integer Overflow. If attackVal is added to balances, ensure it doesn't wrap around.
        // WARNING: Avoid Balance Overflow. Do not use type(uint256).max for ETH amounts.
        // WARNING: Avoid Integer Underflow or Overflow during the attack scenario.
        // SUGGESTION: Use vm.assume to limit attackVal to a safe range.
        // SUGGESTION: Use type(uint128).max as a safe upper bound for balance math.
        // SUGGESTION: Limit the exploit to 1 initial call and 1 re-entrant call for simplicity.
        

        // --- 2. State Configuration (Pre-Condition) ---
        // [LLM_INSTRUCTION]: Does the vulnerable function require specific state?

        // STRATEGY A: Public Methods (Preferred)
        // Call public setters or 'deposit' functions.

        // STRATEGY B: Storage Manipulation (For Private/Hard-to-reach State)
        // If the variable is private or requires complex logic to set, use 'vm.store' or 'stdstore'.
        
        // TIMING: If logic depends on time, use vm.warp(block.timestamp + 100);

        // --- 3. Funding ---
        // [LLM_INSTRUCTION]: Fund the contracts. Use the fuzzed 'attackVal' to ensure sufficient balance.
        
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        // The test contract needs funds because it sends 'attackVal' to the Attacker in the setup step below.
        // Without this, the test will fail with 'EvmError: OutOfFunds' if attackVal > default test balance.
        vm.deal(address(this), attackVal * 2);

        // [LLM_INSTRUCTION]: If the contract requires specific state, set it here.
        
        // --- 4. Trigger Attack ---
        // [LLM_INSTRUCTION]: Pass the Fuzz/Symbolic values to the setup and attack functions.
        // Note: The {value: attackVal} here draws from address(this), which is why we funded it above.
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        // [LLM_INSTRUCTION]: We check the boolean flag on the attacker contract.
        // This flag is only set if the logic inside 'Attacker.attack' confirmed a successful exploit.
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    // Keep this so the test contract can receive Ether from the contract being tested on the "positive" scenario
    receive() external payable {}
}

contract Attacker {
    // [LLM_INSTRUCTION]: Declare the victim contract variable with its specific type.
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    // [LLM_INSTRUCTION]: Declare state variables to store the Fuzz/Symbolic values.
    // We must store them because 'receive()' cannot accept arguments.

    constructor(address victimAddress) { 
        // [LLM_INSTRUCTION]: Cast and store the victim address.
    }

    // [LLM_INSTRUCTION]: Update signature to accept Fuzz/Symbolic values.
    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // [LLM_INSTRUCTION]: Perform preparation steps using the Fuzz/Symbolic value.
        // Check: If the vulnerability requires a 'deposit' first, do it here.
    }

    // [LLM_INSTRUCTION]: Update signature to accept Fuzz/Symbolic values.
    function attack(uint256 val) public {
        // [LLM_INSTRUCTION]: 1. Capture Initial State.
        // Store the balance or state BEFORE the attack triggers to compare later.

        // [LLM_INSTRUCTION]: 2. Store the value for the re-entrant call if needed.

        // [LLM_INSTRUCTION]: 3. Call the vulnerable function.

        // [LLM_INSTRUCTION]: 4. Verify Success Conditions.
        // Set 'exploitSucceeded' to true if the attack was successful.
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // [LLM_INSTRUCTION]: Re-enter the contract using the stored Fuzz/Symbolic value.
            // Note: Do NOT set 'exploitSucceeded' here. Only perform the reentrancy.
            attackCallCount++;
        }
    }
}