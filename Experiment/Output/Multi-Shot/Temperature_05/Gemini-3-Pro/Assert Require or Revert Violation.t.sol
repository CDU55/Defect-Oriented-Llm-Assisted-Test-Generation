
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The contract calculates limit = 100 - 100 = 0.
        // It then requires (id < 0), which is impossible for a uint256.
        // This results in an always-reverting transaction with the specified error message.
        vm.expectRevert(bytes("Value cannot be negative"));

        _contractUnderTest.updateConfiguration(params);
    }
}
