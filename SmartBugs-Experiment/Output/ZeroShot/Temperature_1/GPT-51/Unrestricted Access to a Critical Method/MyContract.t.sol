
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract myContract;

    function setUp() public {
        myContract = new MyContract();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude privileged role: the owner set in constructor (address(this))
        vm.assume(caller != address(this));

        // --- 2. State Configuration ---
        // Fund the contract so it can send ETH out
        vm.deal(address(myContract), 1 ether);

        address payable receiver = payable(address(0xBEEF));
        uint256 amount = 0.1 ether;

        // --- 3. Execution & Assertion ---
        // tx.origin check allows arbitrary caller as long as tx.origin == owner.
        // We simulate this by originating the tx from owner (address(this))
        // while the msg.sender (prank) is an arbitrary caller.
        vm.startPrank(caller, address(this));
        uint256 balanceBefore = receiver.balance;
        myContract.sendTo(receiver, amount);
        uint256 balanceAfter = receiver.balance;
        vm.stopPrank();

        assertEq(balanceAfter - balanceBefore, amount, "Receiver did not get expected funds");
    }
}
