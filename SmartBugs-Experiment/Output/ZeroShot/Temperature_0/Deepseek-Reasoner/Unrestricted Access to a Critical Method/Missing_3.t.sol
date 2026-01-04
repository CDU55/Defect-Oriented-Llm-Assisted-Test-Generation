
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestAccessControlMissing_3 is Test {
    using stdStorage for StdStorage;
    
    Missing_3 public missing3;

    function setUp() public {
        missing3 = new Missing_3();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.prank(caller);
        missing3.Constructor();

        bytes32 ownerSlot = vm.load(address(missing3), bytes32(0));
        address newOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(newOwner, caller, "Arbitrary user became owner");
    }
}
