
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {StdStorage, stdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Unprotected} from "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    using stdStorage for StdStorage;
    
    Unprotected unprotectedContract;

    function setUp() public {
        unprotectedContract = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        address newOwner = address(0x1234567890123456789012345678901234567890);
        
        vm.prank(caller);
        unprotectedContract.changeOwner(newOwner);
        
        assertTrue(true);
    }
}
