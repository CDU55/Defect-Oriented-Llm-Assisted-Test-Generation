
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";

contract TestAssertFailureValidator is Test {
    Validator private _validator;

    function setUp() public {
        _validator = new Validator();
    }

    function test_highlightAssertionFailure() public {
        uint256 invalidValue = 100;

        vm.expectRevert(stdError.arithmeticError);
        _validator.updateConfiguration(Validator.ConfigInput(invalidValue, 0));
    }
}
