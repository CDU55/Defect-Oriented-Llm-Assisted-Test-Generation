
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure() public {
        vm.expectRevert(stdError.arithmeticError);

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 1,
            timestamp: 1
        });

        _contractUnderTest.updateConfiguration(params);
    }
}
