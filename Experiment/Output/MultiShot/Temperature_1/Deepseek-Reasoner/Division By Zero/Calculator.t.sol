// Generation Time: 81,51s
// Input Tokens: 1915
// Output Tokens: 266
// Reasoning Tokens: 2488


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

    function test_highlightThrowsDivisionByZeroException(uint256 divisor) public {
        vm.assume(divisor <= 100); 
        _contractUnderTest.updateMultiplier(divisor);

        try _contractUnderTest.divide(100, divisor) {
        } 
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log(" Input divisor:", divisor);
                console2.log("--------------------------------------------------");
                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
        }
    }
}
