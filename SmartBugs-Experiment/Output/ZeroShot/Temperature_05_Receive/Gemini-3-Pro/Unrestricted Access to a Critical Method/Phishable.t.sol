
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
        
        // Fund the contract to verify withdrawal logic
        vm.deal(address(phishable), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude privileged roles to prove arbitrary access
        vm.assume(caller != owner);
        // Exclude the contract itself
        vm.assume(caller != address(phishable));

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller.
        // We simulate a phishing attack where tx.origin is the owner, 
        // but msg.sender (the caller) is the attacker.
        vm.prank(caller, owner);

        phishable.withdrawAll(payable(caller));
        
        // Assert that the contract was drained, proving the vulnerability
        assertEq(address(phishable).balance, 0);
    }

    receive() external payable {}

    fallback() external payable {}
}
