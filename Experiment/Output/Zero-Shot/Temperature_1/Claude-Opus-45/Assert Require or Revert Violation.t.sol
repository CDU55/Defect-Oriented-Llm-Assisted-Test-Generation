
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator private _validator;

    function setUp() public {
        _validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        // The vulnerability is in the _validate function:
        // uint256 limit = MIN_OFFSET - BASE_LIMIT; 
        // where MIN_OFFSET = 100 and BASE_LIMIT = 100
        // This results in: limit = 100 - 100 = 0
        // 
        // Then the require statement checks: require(_value < limit, "Value cannot be negative")
        // This becomes: require(_value < 0, "Value cannot be negative")
        // 
        // Since _value is a uint256, it can never be less than 0.
        // Therefore, this require statement ALWAYS fails for any input value.
        // This is an "Always-Incorrect Control Flow" - the condition always evaluates to false.

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // Expect the call to revert with the custom error message
        // Since require(_value < 0) always fails, any call will revert
        vm.expectRevert("Value cannot be negative");

        _validator.updateConfiguration(params);
    }

    function test_highlightAlwaysRevertsWithZero() public {
        // Even with id = 0 (the smallest possible uint256 value),
        // the require still fails because 0 < 0 is false
        
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _validator.updateConfiguration(params);
    }

    function test_highlightAlwaysRevertsWithMaxValue() public {
        // With the maximum uint256 value, the require also fails
        
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: type(uint256).max,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _validator.updateConfiguration(params);
    }
}
