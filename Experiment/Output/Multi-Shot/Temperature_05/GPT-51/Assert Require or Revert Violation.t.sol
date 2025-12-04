
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 fuzzId) public {
        // MIN_OFFSET - BASE_LIMIT = 0, so require(_value < 0) always fails.
        vm.expectRevert(bytes("Value cannot be negative"));

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: fuzzId,
            timestamp: block.timestamp
        });

        _contractUnderTest.updateConfiguration(params);
    }
}
