// Generation Time: 8,48s
// Input Tokens: 1958
// Output Tokens: 718
// Reasoning Tokens: 0

// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator private _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 number, uint256 divisor) public {
        // The _calculateDenominator function contains `input / 0` which will always revert
        // with division by zero panic regardless of the input value.
        // This is an unconditional division by zero in the internal function.
        
        try _contractUnderTest.divide(number, divisor) {
            // Execution succeeded - no division by zero occurred
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log(" number:", number);
                console2.log(" divisor:", divisor);
                console2.log(" Note: _calculateDenominator contains 'input / 0'");
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors and ignore them
        }
    }
}
