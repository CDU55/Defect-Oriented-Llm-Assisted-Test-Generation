// Generation Time: 40,67s
// Input Tokens: 1993
// Output Tokens: 176
// Reasoning Tokens: 1629


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 fuzzArg) public {
        vm.assume(fuzzArg >= 0);

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: fuzzArg,
            timestamp: 0
        });

        vm.expectRevert(stdError.assertionError);
        
        _contractUnderTest.updateConfiguration(params);
    }
}
