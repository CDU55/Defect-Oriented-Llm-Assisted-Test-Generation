
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator public calculator;

    function setUp() public {
        calculator = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 input) public {
        try calculator.divide(100, input) {
            // Execution succeeded, no division by zero occurred
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                console2.log("Input value:", input);
                console2.log("Active multiplier:", calculator.activeMultiplier());
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors and ignore them.
        }
    }

    function test_highlightDirectDivisionByZeroInCalculateDenominator() public {
        // The _calculateDenominator function contains `input / 0` which will always revert
        // This test proves the vulnerability exists by calling any function that uses _calculateDenominator
        
        try calculator.divide(100, 50) {
            // This should never succeed due to the division by zero in _calculateDenominator
        } 
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                console2.log("The _calculateDenominator function contains 'input / 0'");
                console2.log("This will always cause a division by zero panic");
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors
        }
    }
}
