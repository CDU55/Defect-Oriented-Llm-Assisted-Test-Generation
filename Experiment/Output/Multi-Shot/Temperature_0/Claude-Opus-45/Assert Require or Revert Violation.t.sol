
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
        // This means require(_value < 0) which is ALWAYS FALSE for any uint256 value
        // since uint256 cannot be negative and 0 < 0 is false.
        // 
        // Therefore, ANY call to updateConfiguration will ALWAYS revert.

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // Expect revert with the error message from the require statement
        // Since limit = 0 and _value < 0 is always false for uint256,
        // the require will always fail
        vm.expectRevert("Value cannot be negative");

        // Trigger the function - this will always revert regardless of input
        _contractUnderTest.updateConfiguration(params);
    }

    function test_highlightAlwaysRevertsWithZero() public {
        // Even with id = 0, the condition 0 < 0 is false
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");
        _contractUnderTest.updateConfiguration(params);
    }

    function test_highlightAlwaysRevertsWithMaxValue() public {
        // With max uint256, the condition is still false
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: type(uint256).max,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");
        _contractUnderTest.updateConfiguration(params);
    }
}
