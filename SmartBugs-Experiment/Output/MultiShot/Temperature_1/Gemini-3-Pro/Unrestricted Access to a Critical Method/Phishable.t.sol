
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;
    address public ownerUser;

    function setUp() public {
        ownerUser = makeAddr("ownerUser");
        _contractUnderTest = new Phishable(ownerUser);
        
        // Fund the contract to verify withdrawal logic
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner to prove arbitrary access
        vm.assume(caller != _contractUnderTest.owner());
        // Exclude the contract itself to ensure balance check works (transferring to self wouldn't reduce balance)
        vm.assume(caller != address(_contractUnderTest));

        // --- 2. State Configuration ---
        // The contract is already funded in setUp.

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller (msg.sender)
        // However, to exploit the tx.origin vulnerability, we must simulate the owner initiating the transaction.
        // vm.prank(msg.sender, tx.origin) -> msg.sender = caller, tx.origin = owner
        vm.prank(caller, _contractUnderTest.owner());

        _contractUnderTest.withdrawAll(payable(caller));

        // Assert that the contract was drained, proving the caller successfully executed the function
        assertEq(address(_contractUnderTest).balance, 0);
    }
}
