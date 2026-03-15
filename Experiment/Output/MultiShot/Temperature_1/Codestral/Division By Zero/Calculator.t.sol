// Generation Time: 1,15s
// Input Tokens: 2444
// Output Tokens: 250
// Reasoning Tokens: 


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

    function test_highlightThrowsDivisionByZeroException(uint256 number) public {
        vm.assume(number < type(uint128).max);

        try _contractUnderTest.divide(number, 0) {
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
