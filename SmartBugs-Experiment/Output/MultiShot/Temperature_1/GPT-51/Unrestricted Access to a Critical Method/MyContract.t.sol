
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

        // Exclude the only privileged address: the owner set in constructor (this test contract)
        vm.assume(caller != address(this));

        vm.assume(amount > 0 && amount <= 1 ether);

        // Fund the contract so it can transfer out funds
        vm.deal(address(_contractUnderTest), amount);

        // Switch context: caller is arbitrary EOA, but enforce tx.origin == owner (address(this))
        vm.startPrank(caller, address(this));
        address payable receiver = payable(address(0xBEEF));

        uint256 beforeBalance = receiver.balance;

        _contractUnderTest.sendTo(receiver, amount);

        uint256 afterBalance = receiver.balance;
        assertEq(afterBalance, beforeBalance + amount);

        vm.stopPrank();
    }
}
