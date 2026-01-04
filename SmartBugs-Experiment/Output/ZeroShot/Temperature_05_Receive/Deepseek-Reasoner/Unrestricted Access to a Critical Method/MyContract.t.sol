
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract myContract;
    address internal constant OWNER_ADDRESS = address(0x1234567890123456789012345678901234567890);

    function setUp() public {
        vm.startPrank(OWNER_ADDRESS);
        myContract = new MyContract();
        vm.deal(address(myContract), 1 ether);
        vm.stopPrank();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != OWNER_ADDRESS);

        vm.deal(caller, 1 ether);

        uint256 amount = 0.1 ether;
        address payable receiver = payable(address(0x999));

        uint256 initialBalance = receiver.balance;

        vm.prank(caller);
        vm.expectRevert();
        myContract.sendTo(receiver, amount);

        assertEq(receiver.balance, initialBalance);
    }

    receive() external payable {}

    fallback() external payable {}
}
