
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable phishable;
    address owner;

    function setUp() public {
        owner = makeAddr("owner");
        phishable = new Phishable(owner);
        vm.deal(address(phishable), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner to prove arbitrary access
        vm.assume(caller != owner);

        // --- 2. State Configuration ---
        // Contract funded in setUp

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller (attacker)
        // We set tx.origin to 'owner' to simulate a phishing attack or bypass the check
        vm.prank(caller, owner);

        phishable.withdrawAll(payable(caller));
        
        // Assert that the contract was drained
        assertEq(address(phishable).balance, 0);
    }
}
