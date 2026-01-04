
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestAccessControlMissing_3 is Test {
    using stdStorage for StdStorage;
    
    Missing_3 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_3();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        bytes32 ownerSlot = keccak256(abi.encodePacked(caller, uint256(0)));
        address currentOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), ownerSlot))));
        vm.assume(caller != currentOwner);
        
        bytes32 initialOwnerSlot = bytes32(uint256(0));
        address initialOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), initialOwnerSlot))));
        vm.assume(caller != initialOwner);

        vm.prank(caller);
        _contractUnderTest.Constructor();

        bytes32 newOwnerSlot = bytes32(uint256(0));
        address newOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), newOwnerSlot))));
        assertEq(newOwner, caller, "Unauthorized address became owner");
    }
}
