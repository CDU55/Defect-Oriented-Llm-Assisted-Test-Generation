// Generation Time: 44,83s
// Input Tokens: 1993
// Output Tokens: 162
// Reasoning Tokens: 1303


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        Validator.ConfigInput memory configInput = Validator.ConfigInput({
            id: id,
            timestamp: block.timestamp
        });

        vm.expectRevert("Value cannot be negative");
        _contractUnderTest.updateConfiguration(configInput);
    }
}
