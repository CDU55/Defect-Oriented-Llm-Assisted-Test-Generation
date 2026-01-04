
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract public myContract;

    function setUp() public {
        myContract = new MyContract();
        vm.deal(address(myContract), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != myContract.owner());

        address payable receiver = payable(address(0x1234));
        uint256 amount = 1 ether;

        vm.prank(caller);
        
        myContract.sendTo(receiver, amount);
    }
}
