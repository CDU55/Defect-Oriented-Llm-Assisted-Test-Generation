
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable phishable;
    address owner;

    function setUp() public {
        owner = address(0xABCD);
        phishable = new Phishable(owner);

        // Fund the contract so withdrawAll has an effect
        vm.deal(address(this), 10 ether);
        (bool sent, ) = address(phishable).call{value: 10 ether}("");
        require(sent, "funding failed");
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable recipient) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude privileged role: owner (the only intended authorized caller)
        vm.assume(caller != owner);

        // Constrain recipient to a non-zero address to observe balance changes
        vm.assume(recipient != address(0));

        // --- 2. State Configuration ---
        uint256 contractBalanceBefore = address(phishable).balance;
        vm.assume(contractBalanceBefore > 0);

        uint256 recipientBalanceBefore = recipient.balance;

        // --- 3. Execution & Assertion ---
        vm.prank(caller);

        // This will succeed if the vulnerability exists because access control
        // is based on tx.origin, not msg.sender.
        phishable.withdrawAll(recipient);

        // Assert that the funds were actually withdrawn to the recipient
        assertEq(address(phishable).balance, 0, "contract balance should be drained");
        assertEq(
            recipient.balance,
            recipientBalanceBefore + contractBalanceBefore,
            "recipient should receive all funds"
        );
    }
}
