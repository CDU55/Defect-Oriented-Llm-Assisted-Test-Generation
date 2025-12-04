
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
        // The vulnerability is in _validate function:
        // uint256 limit = MIN_OFFSET - BASE_LIMIT; 
        // where MIN_OFFSET = 100 and BASE_LIMIT = 100
        // This results in: limit = 100 - 100 = 0
        // 
        // Then the require check is:
        // require(_value < limit, "Value cannot be negative");
        // which becomes: require(_value < 0, "Value cannot be negative");
        //
        // Since _value is uint256, it can never be less than 0.
        // This means the require will ALWAYS fail for any input value.
        // This is an "Always-Incorrect Control Flow" - the condition always evaluates
        // in a way that causes inevitable reverts.

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The function will always revert with the custom error message
        // because no uint256 value can be less than 0
        vm.expectRevert("Value cannot be negative");

        _validator.updateConfiguration(params);
    }

    function test_highlightAlwaysRevertsWithZero() public {
        // Even with id = 0 (the smallest possible uint256 value),
        // the require(_value < 0) will fail because 0 is not less than 0
        
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _validator.updateConfiguration(params);
    }

    function test_highlightAlwaysRevertsWithMaxValue() public {
        // With the maximum uint256 value, the require still fails
        // This demonstrates the condition is always false regardless of input
        
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: type(uint256).max,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");

        _validator.updateConfiguration(params);
    }
}
