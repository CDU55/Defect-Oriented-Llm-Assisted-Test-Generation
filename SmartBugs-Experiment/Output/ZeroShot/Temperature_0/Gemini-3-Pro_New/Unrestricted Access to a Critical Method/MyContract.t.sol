
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {

    MyContract myContract;
    address ownerAddress;

    function setUp() public {
        myContract = new MyContract();
        
        // Fund the contract to allow transfers
        vm.deal(address(myContract), 100 ether);

        // Retrieve the private owner address from storage slot 0 to exclude it from fuzzing
        ownerAddress = address(uint160(uint256(vm.load(address(myContract), bytes32(uint256(0))))));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner to prove that an arbitrary (non-owner) user can access the function
        vm.assume(caller != ownerAddress);

        // --- 2. State Configuration ---
        uint256 amount = 1 ether;
        uint256 preBalance = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller.
        // Note: vm.prank(caller) sets msg.sender to 'caller' but leaves tx.origin as the test runner (owner).
        // This successfully reproduces the vulnerability where the check (tx.origin == owner) passes
        // even though the immediate caller (msg.sender) is unauthorized.
        vm.prank(caller);

        myContract.sendTo(payable(caller), amount);
        
        assertEq(caller.balance, preBalance + amount);
    }
}
