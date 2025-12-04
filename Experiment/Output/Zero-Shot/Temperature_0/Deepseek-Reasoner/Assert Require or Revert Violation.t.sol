
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

contract TestAssertFailureValidator is Test {
    Validator public validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        vm.expectRevert("Value cannot be negative");
        validator.updateConfiguration(params);
    }
}
