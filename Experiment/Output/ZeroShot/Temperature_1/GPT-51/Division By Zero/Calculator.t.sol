// Generation Time: 10,06s
// Input Tokens: 1460
// Output Tokens: 262
// Reasoning Tokens: 1159


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator calculator;

    function setUp() public {
        calculator = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 number, uint256 divisor) public {
        try calculator.divide(number, divisor) returns (uint256 result) {
            // If this succeeds, division-by-zero was not triggered for this input.
        } 
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log(" number:", number);
                console2.log(" divisor:", divisor);
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
            // Ignore other errors.
        }
    }
}
