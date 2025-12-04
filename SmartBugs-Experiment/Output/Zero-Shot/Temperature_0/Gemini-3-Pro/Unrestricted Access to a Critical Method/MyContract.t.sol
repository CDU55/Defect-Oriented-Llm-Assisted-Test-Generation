
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {

    MyContract myContract;

    function setUp() public {
        myContract = new MyContract();
        // Fund the contract so it has balance to transfer
        vm.deal(address(myContract), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner. In this contract, owner is set to msg.sender (address(this)) in constructor.
        // We have already excluded address(this) above.

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller.
        // We set both msg.sender and tx.origin to 'caller' to ensure we test the tx.origin check properly.
        vm.prank(caller, caller);

        // TRIGGER VULNERABILITY
        // Attempt to call the sensitive function.
        // If the vulnerability exists (Unrestricted Access), this call will succeed.
        myContract.sendTo(payable(caller), 1 ether);
    }
}
