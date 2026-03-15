// Generation Time: 22,24s
// Input Tokens: 1994
// Output Tokens: 1032
// Reasoning Tokens: 779

// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator private validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        // The vulnerability: MIN_OFFSET - BASE_LIMIT = 100 - 100 = 0
        // The require statement becomes: require(_value < 0, "Value cannot be negative")
        // Since _value is uint256, it can never be less than 0
        // This condition ALWAYS evaluates to false, causing inevitable revert
        
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // Expect revert with the error message from the require statement
        // This proves the require condition always fails regardless of input
        vm.expectRevert("Value cannot be negative");
        
        validator.updateConfiguration(params);
    }
}
