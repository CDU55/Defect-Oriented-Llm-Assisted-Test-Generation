
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract Malicious {
    function attack(address payable receiver, uint amount, address target) public {
        MyContract(target).sendTo(receiver, amount);
    }
}

contract TestAccessControlMyContract is Test {
    MyContract public myContract;
    address public ownerAddr;
    bytes public maliciousCode;
    address public dummyAddr;

    function setUp() public {
        ownerAddr = makeAddr("owner");
        vm.prank(ownerAddr);
        myContract = new MyContract();

        Malicious dummy = new Malicious();
        dummyAddr = address(dummy);
        maliciousCode = vm.getCode(dummyAddr);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint amount) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != ownerAddr);
        vm.assume(caller != dummyAddr);
        vm.assume(receiver != address(0));
        vm.assume(amount > 0 && amount <= 100 ether);

        // --- 2. State Configuration ---
        vm.deal(address(myContract), 100 ether);

        vm.etch(caller, maliciousCode);

        // --- 3. Execution & Assertion ---
        uint balanceBefore = receiver.balance;
        vm.prank(ownerAddr);
        Malicious(caller).attack(receiver, amount, address(myContract));
        assertEq(receiver.balance, balanceBefore + amount);
    }
}
