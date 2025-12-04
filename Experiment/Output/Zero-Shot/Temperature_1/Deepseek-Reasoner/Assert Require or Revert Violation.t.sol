
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");
        validator.updateConfiguration(params);
    }
}
