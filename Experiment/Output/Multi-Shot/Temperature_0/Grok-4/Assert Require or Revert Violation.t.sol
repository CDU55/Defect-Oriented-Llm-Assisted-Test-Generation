
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "forge-std/Test.sol";

import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        vm.expectRevert(bytes("Value cannot be negative"));

        _contractUnderTest.updateConfiguration(Validator.ConfigInput(id, timestamp));
    }
}
