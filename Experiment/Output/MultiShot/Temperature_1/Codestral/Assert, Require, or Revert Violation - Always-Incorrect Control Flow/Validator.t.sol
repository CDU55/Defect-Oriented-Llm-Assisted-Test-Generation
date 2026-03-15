// Generation Time: 0,83s
// Input Tokens: 2501
// Output Tokens: 142
// Reasoning Tokens: 


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure() public {
        vm.expectRevert(stdError.arithmeticError);

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 100,
            timestamp: block.timestamp
        });

        _contractUnderTest.updateConfiguration(params);
    }
}
