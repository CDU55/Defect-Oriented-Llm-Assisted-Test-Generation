
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure() public {
        // The internal logic computes:
        // limit = MIN_OFFSET - BASE_LIMIT = 100 - 100 = 0
        // and requires _value < 0, which is impossible for uint256.
        // Any input will always violate the require condition.
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: block.timestamp
        });

        vm.expectRevert(bytes("Value cannot be negative"));
        _contractUnderTest.updateConfiguration(params);
    }
}
