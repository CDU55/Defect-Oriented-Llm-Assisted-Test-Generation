
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Phishable(address(0xBEEF));
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable recipient) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the privileged owner (tx.origin == owner)
        vm.assume(caller != _contractUnderTest.owner());

        uint256 initialContractBalance = address(_contractUnderTest).balance;
        vm.assume(initialContractBalance > 0);

        // Ensure recipient is a valid address different from the contract
        vm.assume(recipient != address(0));
        vm.assume(recipient != address(_contractUnderTest));

        uint256 initialRecipientBalance = recipient.balance;

        // Simulate a phishing scenario:
        // tx.origin will be the owner, but msg.sender (prank) is an arbitrary caller.
        vm.startPrank(_contractUnderTest.owner(), caller);
        _contractUnderTest.withdrawAll(recipient);
        vm.stopPrank();

        assertEq(address(_contractUnderTest).balance, 0);
        assertEq(recipient.balance, initialRecipientBalance + initialContractBalance);
    }
}
