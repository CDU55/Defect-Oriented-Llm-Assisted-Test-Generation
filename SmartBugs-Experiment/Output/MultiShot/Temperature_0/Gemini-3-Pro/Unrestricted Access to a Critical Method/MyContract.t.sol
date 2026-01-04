
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new MyContract();
        // Fund the contract to ensure the transfer in sendTo does not fail due to lack of funds
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner. 
        // In setUp, MyContract is deployed by this test contract, so owner = address(this).
        // We have already excluded address(this) above.

        // --- 2. State Configuration ---
        // No specific state configuration needed beyond funding the contract in setUp.

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller. 
        // We use the 2-argument version of prank to set both msg.sender and tx.origin to 'caller'.
        vm.prank(caller, caller);

        // Trigger Vulnerability: Attempt to call the sensitive function
        _contractUnderTest.sendTo(payable(caller), 1 ether);
    }
}
