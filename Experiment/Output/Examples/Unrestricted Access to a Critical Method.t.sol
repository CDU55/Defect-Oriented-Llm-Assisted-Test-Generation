// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {UnprotectedSelfdestruct} from "../src/UnprotectedSelfdestruct.sol";

contract TestAccessControlUnprotectedSelfdestruct is Test {
    UnprotectedSelfdestruct public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new UnprotectedSelfdestruct();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // 1. Exclude the Test Contract itself
        vm.assume(caller != address(this));
        
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        // This catches the 'FoundryCheat' address reliably
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // 4. Exclude the Contract Under Test
        vm.assume(caller != address(_contractUnderTest));

        // Funding: The contract requires balance > _totalAllocated (0) to proceed
        vm.deal(address(_contractUnderTest), 1 ether);

        vm.prank(caller);

        _contractUnderTest.cancelContract();
    }
}