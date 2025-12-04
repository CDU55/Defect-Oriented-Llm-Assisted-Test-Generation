
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
        // Prepare the input struct
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The contract has a logic flaw where it calculates `limit` as 0 (100 - 100)
        // and checks `require(_value < limit)`. Since `_value` is uint256, it cannot be less than 0.
        // This causes an inevitable revert with the message "Value cannot be negative".
        vm.expectRevert("Value cannot be negative");

        // Trigger the vulnerability
        _contractUnderTest.updateConfiguration(params);
    }
}
