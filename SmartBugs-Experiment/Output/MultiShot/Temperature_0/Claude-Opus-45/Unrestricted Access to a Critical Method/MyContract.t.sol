
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {

    MyContract public _contractUnderTest;
    address public owner;

    function setUp() public {
        owner = address(this);
        _contractUnderTest = new MyContract();
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint256 amount) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner (the privileged role)
        vm.assume(caller != owner);
        
        // Constrain receiver to be a valid address
        vm.assume(receiver != address(0));
        vm.assume(receiver != address(vm));
        vm.assume(receiver != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Constrain amount to be within contract balance
        vm.assume(amount > 0 && amount <= address(_contractUnderTest).balance);

        // --- 2. State Configuration ---
        
        // The vulnerability here is the use of tx.origin instead of msg.sender.
        // An attacker can create a malicious contract that tricks the owner into calling it,
        // which then calls sendTo. In this case, tx.origin would be the owner,
        // but msg.sender would be the attacker's contract.
        
        // To demonstrate this, we simulate the owner initiating a transaction
        // that goes through an intermediary (the arbitrary caller acting as a proxy).
        
        uint256 receiverBalanceBefore = receiver.balance;

        // --- 3. Execution & Assertion ---
        
        // The vulnerability: tx.origin check can be bypassed through a proxy call.
        // We simulate the owner calling a malicious contract (caller) which then calls sendTo.
        // tx.origin will be 'owner', but the actual caller is the malicious contract.
        
        // First, set tx.origin to owner (simulating owner initiated the transaction chain)
        vm.prank(caller, owner);
        
        // The arbitrary caller can now call sendTo because tx.origin == owner
        // even though msg.sender is the arbitrary caller (not the owner)
        _contractUnderTest.sendTo(receiver, amount);

        // Assert that the transfer actually happened
        assertEq(receiver.balance, receiverBalanceBefore + amount);
    }
}
