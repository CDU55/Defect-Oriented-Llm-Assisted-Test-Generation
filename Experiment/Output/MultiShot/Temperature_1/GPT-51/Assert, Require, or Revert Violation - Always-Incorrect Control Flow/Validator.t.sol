// Generation Time: 9,60s
// Input Tokens: 1586
// Output Tokens: 154
// Reasoning Tokens: 1327


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
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: block.timestamp
        });

        vm.expectRevert(bytes("Value cannot be negative"));
        _contractUnderTest.updateConfiguration(params);
    }
}
