// Generation Time: 9,60s
// Input Tokens: 1965
// Output Tokens: 613
// Reasoning Tokens: 0

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
        // This means limit = 100 - 100 = 0
        // 
        // The require statement is: require(_value < limit, "Value cannot be negative");
        // This becomes: require(_value < 0, "Value cannot be negative");
        // 
        // Since _value is a uint256, it can never be less than 0.
        // This means the require will ALWAYS fail for any input value,
        // causing an inevitable revert with the custom error message.

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // Expect the call to revert with the custom error message
        // since the condition _value < 0 can never be true for uint256
        vm.expectRevert("Value cannot be negative");

        _validator.updateConfiguration(params);
    }
}
