
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id) public {
        vm.expectRevert("Value cannot be negative");
        
        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: block.timestamp
        });
        
        _contractUnderTest.updateConfiguration(params);
    }
}
