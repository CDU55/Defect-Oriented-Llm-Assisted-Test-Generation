// Generation Time: 25,94s
// Input Tokens: 1869
// Output Tokens: 159
// Reasoning Tokens: 935


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";

import "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        vm.assume(id >= 0);
        
        Validator.ConfigInput memory config = Validator.ConfigInput({
            id: id,
            timestamp: block.timestamp
        });

        vm.expectRevert("Value cannot be negative");
        
        validator.updateConfiguration(config);
    }
}
