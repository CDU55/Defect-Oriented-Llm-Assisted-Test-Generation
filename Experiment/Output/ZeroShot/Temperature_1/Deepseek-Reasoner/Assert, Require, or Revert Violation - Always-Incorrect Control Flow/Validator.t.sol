// Generation Time: 28,70s
// Input Tokens: 1869
// Output Tokens: 158
// Reasoning Tokens: 1062


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        vm.assume(id >= 0);

        Validator.ConfigInput memory configInput = Validator.ConfigInput({
            id: id,
            timestamp: 0
        });

        vm.expectRevert("Value cannot be negative");
        validator.updateConfiguration(configInput);
    }
}
