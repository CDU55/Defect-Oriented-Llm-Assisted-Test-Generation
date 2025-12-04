
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The contract calculates limit = 100 - 100 = 0.
        // It then checks require(id < 0, "Value cannot be negative").
        // Since id is a uint256, it can never be less than 0.
        // This results in an inevitable revert for any input.
        vm.expectRevert("Value cannot be negative");

        validator.updateConfiguration(params);
    }
}
