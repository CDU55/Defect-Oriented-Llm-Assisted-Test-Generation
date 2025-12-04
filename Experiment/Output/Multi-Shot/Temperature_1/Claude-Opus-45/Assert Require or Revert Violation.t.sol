
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
        // The vulnerability is in _validate():
        // uint256 limit = MIN_OFFSET - BASE_LIMIT;
        // where MIN_OFFSET = 100 and BASE_LIMIT = 100
        // So limit = 100 - 100 = 0
        // 
        // Then: require(_value < limit, "Value cannot be negative");
        // This becomes: require(_value < 0, "Value cannot be negative");
        // 
        // Since _value is uint256, it can never be less than 0.
        // This means the require ALWAYS fails, making the function uncallable
        // with any input value.

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The require statement will always revert because no uint256 can be < 0
        // This is an "Always-Incorrect Control Flow" - the condition is impossible to satisfy
        vm.expectRevert("Value cannot be negative");

        _contractUnderTest.updateConfiguration(params);
    }

    function test_highlightAlwaysReverts_withZero() public {
        // Even with id = 0 (the smallest possible uint256 value),
        // the condition _value < 0 is still false
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _contractUnderTest.updateConfiguration(params);
    }

    function test_highlightAlwaysReverts_withMaxValue() public {
        // With max uint256, still reverts
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: type(uint256).max,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _contractUnderTest.updateConfiguration(params);
    }
}
