
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 _id) public {
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: _id,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");
        validator.updateConfiguration(params);
    }
}
