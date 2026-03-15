// Generation Time: 10,24s
// Input Tokens: 2115
// Output Tokens: 613
// Reasoning Tokens: 0

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
        // require(_value < limit, "Value cannot be negative"); // _value < 0 is always false for uint256
        // 
        // Since limit is always 0, and _value is uint256 (always >= 0),
        // the condition _value < 0 is ALWAYS FALSE for any non-negative value.
        // This means the require will ALWAYS revert for any input value.
        
        // No constraints needed - ANY input will trigger the revert
        // because the condition _value < 0 is impossible to satisfy with uint256
        
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // Expect revert with the custom error message since require always fails
        vm.expectRevert("Value cannot be negative");

        _contractUnderTest.updateConfiguration(params);
    }
}
