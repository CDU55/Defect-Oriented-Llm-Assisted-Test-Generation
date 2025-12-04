
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
        try _contractUnderTest.divide(100, 0) {
        }
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        }
        catch {
        }
    }
}
