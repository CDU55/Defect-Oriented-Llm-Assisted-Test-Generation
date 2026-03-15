// Generation Time: 1,79s
// Input Tokens: 2444
// Output Tokens: 241
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
        _contractUnderTest.updateMultiplier(1);

        try _contractUnderTest.divide(100, 0) {
        }
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");

                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        }
        catch {
        }
    }
}
