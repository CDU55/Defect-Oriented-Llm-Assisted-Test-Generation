// Generation Time: 0,77s
// Input Tokens: 2373
// Output Tokens: 134
// Reasoning Tokens: 


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";

contract TestAssertFailureValidator is Test {

    Validator private _validator;

    function setUp() public {
        _validator = new Validator();
    }

    function test_highlightAssertionFailure() public {
        vm.expectRevert(stdError.arithmeticError);

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 1,
            timestamp: 1
        });

        _validator.updateConfiguration(params);
    }
}
