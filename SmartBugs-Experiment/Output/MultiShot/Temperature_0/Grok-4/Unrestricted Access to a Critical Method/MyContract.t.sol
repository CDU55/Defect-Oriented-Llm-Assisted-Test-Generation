
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract public _contractUnderTest;
    address public ownerAddr;

    function setUp() public {
        ownerAddr = makeAddr("owner");
        vm.prank(ownerAddr);
        _contractUnderTest = new MyContract();
        vm.deal(address(_contractUnderTest), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint256 amount) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != ownerAddr);
        vm.assume(receiver != address(0));
        vm.assume(amount > 0 && amount <= 1 ether);

        uint balBefore = receiver.balance;

        vm.prank(caller, ownerAddr);
        _contractUnderTest.sendTo(receiver, amount);

        assertEq(receiver.balance, balBefore + amount);
    }
}
