// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DivideByZeroMinimal} from "../src/DivideByZeroMinimal.sol";
import {console2} from "forge-std/console2.sol";
contract TestDivisionByZero is Test {
    DivideByZeroMinimal public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new DivideByZeroMinimal();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 number, uint256 divisor, uint256 multiplier) public {
        // 1. Constraints
        vm.assume(multiplier > 0);
        vm.assume(multiplier < type(uint256).max / 50);

        // Prevent Underflow (0x11) so we can reach the Division logic
        uint256 offset = 50 * multiplier;
        vm.assume(divisor >= offset);

        _contractUnderTest.updateMultiplier(multiplier);

        // 2. Try/Catch to swallow the error
        try _contractUnderTest.divide(number, divisor) {
            // Success - do nothing
        } 
        catch Panic(uint256 errorCode) {
            // Check for Division by Zero (0x12)
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                console2.log("--------------------------------------------------");
                // The test reaches the end of the function successfully -> PASS
                revert();
            }
        } 
        catch {
            // Ignore other errors
        }
    }
}