
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightRequireFailure(uint256 id, uint256 timestamp) public {
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The contract calculates limit = 100 - 100 = 0.
        // It then requires (params.id < 0). Since params.id is uint256, it cannot be less than 0.
        // This condition is always false, causing an inevitable revert with the specified message.
        vm.expectRevert("Value cannot be negative");
        
        _contractUnderTest.updateConfiguration(params);
    }
}
