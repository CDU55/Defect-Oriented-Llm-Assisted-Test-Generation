
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract myContract;

    function setUp() public {
        myContract = new MyContract();
    }

    function test_highlightArbitraryUserCanAccess(address caller, uint256 amount) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the privileged role: the owner set in the constructor
        vm.assume(caller != address(this));

        // Constrain amount to something reasonable
        vm.assume(amount > 0 && amount <= 1 ether);

        // --- 2. State Configuration ---
        // Fund the contract so it can transfer out funds
        vm.deal(address(myContract), amount);

        // Ensure tx.origin is the privileged owner while msg.sender is the arbitrary caller
        // We do this by starting a prank from the owner (this contract) with a different msg.sender (caller)
        vm.startPrank(address(this), caller);

        // --- 3. Execution & Assertion ---
        // Call the vulnerable function: tx.origin == owner passes, even though msg.sender is arbitrary
        myContract.sendTo(payable(caller), amount);

        vm.stopPrank();

        // Assert that the arbitrary caller received the funds
        assertEq(caller.balance, amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
