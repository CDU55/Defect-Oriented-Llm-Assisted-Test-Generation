
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new MyContract();
    }

    function test_highlightArbitraryUserCanAccess(address caller, uint256 amount) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the privileged role: the owner set in the constructor (this contract)
        vm.assume(caller != address(this));

        // Constrain amount to something reasonable and non-zero
        vm.assume(amount > 0 && amount <= 1 ether);

        // Fund the contract so it can transfer out funds
        vm.deal(address(_contractUnderTest), amount);

        // Also fund the caller so they can pay gas (not strictly necessary but harmless)
        vm.deal(caller, 1 ether);

        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Attempt to call the critical function as a non-owner msg.sender
        // This should still succeed because the contract uses tx.origin for auth
        _contractUnderTest.sendTo(payable(caller), amount);

        // Assert that the caller received the funds, proving they could invoke the method
        assertEq(caller.balance, 1 ether + amount);
    }
}
