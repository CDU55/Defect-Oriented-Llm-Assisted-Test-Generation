// Generation Time: 14,74s
// Input Tokens: 2070
// Output Tokens: 709
// Reasoning Tokens: 353

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
        
        try _contractUnderTest.divide(number, divisor) {
            // Execution succeeded - no division by zero occurred
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log(" Input number:", number);
                console2.log(" Input divisor:", divisor);
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors and ignore them
        }
    }
}
