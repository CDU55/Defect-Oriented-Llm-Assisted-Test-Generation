
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

        // The target contract calculates limit = 100 - 100 = 0.
        // It then requires (id < 0), which is impossible for a uint256.
        // This results in an inevitable revert with the message "Value cannot be negative".
        vm.expectRevert("Value cannot be negative");

        validator.updateConfiguration(params);
    }
}
