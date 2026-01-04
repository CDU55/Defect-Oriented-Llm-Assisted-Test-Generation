
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable phishable;
    address owner;
    
    function setUp() public {
        owner = address(0x1234);
        phishable = new Phishable(owner);
        
        // Fund the contract with some ether to make withdrawal meaningful
        vm.deal(address(phishable), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // Constraints
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // CRITICAL: Exclude the privileged role (owner) from the caller
        // We want to test that a non-owner can access the function
        vm.assume(caller != owner);
        
        // Record initial balances
        uint256 initialRecipientBalance = caller.balance;
        uint256 initialContractBalance = address(phishable).balance;
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // TRIGGER VULNERABILITY: Call withdrawAll as arbitrary user
        // This should fail due to tx.origin == owner check, proving the vulnerability is NOT present
        // The function actually has access control (tx.origin check), so this will revert
        // This test demonstrates that the function IS protected against arbitrary callers
        phishable.withdrawAll(payable(caller));
        
        // If we reach here, the vulnerability exists (but it doesn't in this contract)
        // Assert that funds were transferred
        uint256 finalRecipientBalance = caller.balance;
        uint256 finalContractBalance = address(phishable).balance;
        
        assertEq(
            finalRecipientBalance,
            initialRecipientBalance + initialContractBalance,
            "Recipient should have received contract balance"
        );
        assertEq(finalContractBalance, 0, "Contract balance should be zero");
    }
}
