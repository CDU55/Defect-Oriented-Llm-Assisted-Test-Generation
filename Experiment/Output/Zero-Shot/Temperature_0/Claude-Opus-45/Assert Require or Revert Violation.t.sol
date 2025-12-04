
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {Validator} from "../src/Validator.sol";

contract TestAssertFailureValidator is Test {
    Validator private _validator;

    function setUp() public {
        _validator = new Validator();
    }

    function test_highlightAssertionFailure(uint256 id, uint256 timestamp) public {
        // The vulnerability is in _validate function:
        // uint256 limit = MIN_OFFSET - BASE_LIMIT; // 100 - 100 = 0
        // require(_value < limit, "Value cannot be negative");
        // 
        // Since limit is always 0, and _value is uint256 (always >= 0),
        // the condition _value < 0 is ALWAYS FALSE for any non-negative value.
        // This means the require will ALWAYS revert for any input.
        
        // This is an "Always-Incorrect Control Flow" because:
        // - The require condition can never be satisfied
        // - Every call to updateConfiguration will revert
        
        // Expect revert with the custom error message (not assertion error)
        // Since require fails, it reverts with the error message
        vm.expectRevert("Value cannot be negative");

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: id,
            timestamp: timestamp
        });
        
        _validator.updateConfiguration(params);
    }

    function test_highlightAlwaysReverts_ZeroValue() public {
        // Even with id = 0, the smallest possible uint256 value,
        // the require(_value < 0) will fail because 0 < 0 is false
        
        vm.expectRevert("Value cannot be negative");

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: 0,
            timestamp: 0
        });
        
        _validator.updateConfiguration(params);
    }

    function test_highlightAlwaysReverts_MaxValue() public {
        // With maximum uint256 value, it also reverts
        
        vm.expectRevert("Value cannot be negative");

        Validator.ConfigInput memory params = Validator.ConfigInput({
            id: type(uint256).max,
            timestamp: 0
        });
        
        _validator.updateConfiguration(params);
    }

    function test_highlightNoValidInputExists() public {
        // This test proves that NO valid input can pass the validation
        // by trying multiple representative values
        
        uint256[5] memory testValues = [
            uint256(0),
            uint256(1),
            uint256(50),
            uint256(100),
            type(uint256).max
        ];
        
        for (uint256 i = 0; i < testValues.length; i++) {
            Validator.ConfigInput memory params = Validator.ConfigInput({
                id: testValues[i],
                timestamp: block.timestamp
            });
            
            vm.expectRevert("Value cannot be negative");
            _validator.updateConfiguration(params);
        }
    }
}
