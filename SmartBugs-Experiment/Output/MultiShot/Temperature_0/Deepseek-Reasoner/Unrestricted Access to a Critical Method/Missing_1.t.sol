
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestAccessControlMissing_1 is Test {
    using stdStorage for StdStorage;
    
    Missing_1 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_1();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.prank(caller);
        _contractUnderTest.IamMissing();
        
        bytes32 ownerSlot = bytes32(uint256(0));
        address storedOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), ownerSlot))));
        assertEq(storedOwner, caller, "Arbitrary caller became owner");
    }
}
