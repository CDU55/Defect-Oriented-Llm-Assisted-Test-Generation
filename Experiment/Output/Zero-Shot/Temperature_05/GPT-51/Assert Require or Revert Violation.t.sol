
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        vm.assume(id > 0);

        vm.expectRevert(bytes("Value cannot be negative"));

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: block.timestamp
        });

        validator.updateConfiguration(params);
    }
}
