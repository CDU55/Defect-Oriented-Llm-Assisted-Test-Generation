
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        // The vulnerability is in _validate function:
        // uint256 limit = MIN_OFFSET - BASE_LIMIT; // 100 - 100 = 0
        // require(_value < limit, "Value cannot be negative");
        // 
        // This means require(_value < 0) which is ALWAYS FALSE for uint256
        // since uint256 cannot be negative, no value can be less than 0.
        // This causes the require to ALWAYS revert, making the function unusable.

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The require will always fail because no uint256 can be < 0
        // This is a "Require Violation - Always-Incorrect Control Flow"
        vm.expectRevert("Value cannot be negative");

        _contractUnderTest.updateConfiguration(params);
    }

    function test_highlightAlwaysReverts_withZero() public {
        // Even with id = 0, the smallest possible uint256 value,
        // the require(_value < 0) will still fail
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _contractUnderTest.updateConfiguration(params);
    }

    function test_highlightAlwaysReverts_withMaxValue() public {
        // With the maximum uint256 value, it still reverts
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: type(uint256).max,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _contractUnderTest.updateConfiguration(params);
    }
}
