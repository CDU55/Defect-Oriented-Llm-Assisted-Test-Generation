
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable phishable;
    address owner;

    function setUp() public {
        owner = address(0xABCD);
        vm.deal(owner, 10 ether);
        vm.prank(owner);
        phishable = new Phishable(owner);

        // Fund the Phishable contract so withdrawAll has an observable effect
        vm.deal(address(phishable), 5 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable recipient) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the privileged role: the owner
        vm.assume(caller != owner);

        // Constrain recipient to a non-zero, non-cheat address for clarity
        vm.assume(recipient != address(0));
        vm.assume(recipient != address(vm));

        // --- 2. State Configuration ---
        uint256 initialContractBalance = address(phishable).balance;
        vm.assume(initialContractBalance > 0);

        uint256 initialRecipientBalance = recipient.balance;

        // --- 3. Execution & Assertion ---
        vm.prank(caller);

        // This should revert for non-owner if access control were correct.
        // Because the contract uses tx.origin == owner, any arbitrary EOA
        // that is the original transaction sender can drain funds.
        phishable.withdrawAll(recipient);

        // Assert that funds were actually moved out of the contract
        assertEq(address(phishable).balance, 0);
        assertEq(recipient.balance, initialRecipientBalance + initialContractBalance);
    }
}
