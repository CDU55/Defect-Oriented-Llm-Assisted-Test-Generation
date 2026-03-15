// Generation Time: 2,07s
// Input Tokens: 2366
// Output Tokens: 290
// Reasoning Tokens: 


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException() public {
        uint256 number = 100;
        uint256 divisor = 0;

        try _contractUnderTest.divide(number, divisor) {
        }
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");

                console2.log("Number:", number);
                console2.log("Divisor:", divisor);
                console2.log("Denominator:", _contractUnderTest._calculateDenominator(divisor));
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        }
        catch {
        }
    }
}
