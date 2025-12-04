
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator validator;

    function setUp() public {
        validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Value cannot be negative")
        );

        validator.updateConfiguration(params);
    }
}
