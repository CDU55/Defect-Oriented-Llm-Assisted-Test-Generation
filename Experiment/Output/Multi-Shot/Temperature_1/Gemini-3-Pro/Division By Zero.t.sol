
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 number, uint256 divisor) public {
        
        // --- 1. Constraints (Optional) ---
        // No specific constraints strictly required for fuzzing to find the issue,
        // but limiting divisor size might speed up finding the specific value '100' if the range is huge.
        // However, standard fuzzing handles this well.

        // --- 2. State Configuration (Pre-Condition) ---
        // State is already set with default constants (STARTER = 50, activeMultiplier = 2).
        // Target calculation is: input - (50 * 2) = input - 100.
        // If input is 100, denominator becomes 0.

        // --- 3. Trigger & Log Strategy ---
        try _contractUnderTest.divide(number, divisor) {
            // Case: Execution Succeeded. Do nothing.
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                
                console2.log(" Number:", number);
                console2.log(" Divisor:", divisor);
                
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors (e.g., standard reverts, arithmetic underflow 0x11) and ignore them.
        }
    }
}
