
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        vm.assume(id < type(uint256).max);
        
        Validator.ConfigInput memory configInput = Validator.ConfigInput({
            id: id,
            timestamp: block.timestamp
        });

        vm.expectRevert("Value cannot be negative");
        _contractUnderTest.updateConfiguration(configInput);
    }
}
