
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract public _contractUnderTest;
    address public owner;

    function setUp() public {
        _contractUnderTest = new MyContract();
        owner = address(this);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != owner);

        uint256 contractBalance = 1 ether;
        vm.deal(address(_contractUnderTest), contractBalance);
        
        address payable receiver = payable(caller);
        uint256 amount = 0.5 ether;

        uint256 initialBalance = receiver.balance;

        vm.prank(caller);
        
        _contractUnderTest.sendTo(receiver, amount);

        assertEq(receiver.balance, initialBalance + amount);
    }
}
