
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";

contract TestAssertFailureValidator is Test {
    Validator public validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure() public {
        vm.expectRevert(stdError.arithmeticError);

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: 0
        });

        validator.updateConfiguration(params);
    }
}
