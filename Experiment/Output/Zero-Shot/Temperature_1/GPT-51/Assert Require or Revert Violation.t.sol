
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator internal validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        vm.expectRevert(bytes("Value cannot be negative"));

        validator.updateConfiguration(
            Validator.ConfigInput({id: id, timestamp: block.timestamp})
        );
    }
}
