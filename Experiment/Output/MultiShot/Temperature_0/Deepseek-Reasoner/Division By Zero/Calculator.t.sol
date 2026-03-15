// Generation Time: 66,50s
// Input Tokens: 1915
// Output Tokens: 339
// Reasoning Tokens: 2495


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
        uint256 denom = divisor;
        
        vm.assume(denom > 0);
        
        if (denom / 0 == 0) {
            uint256 adjusted = denom - (50 * _contractUnderTest.activeMultiplier());
            vm.assume(adjusted == 0);
        }

        try _contractUnderTest.divide(number, divisor) {
        } 
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log(" Input Number:", number);
                console2.log(" Input Divisor:", divisor);
                console2.log(" Active Multiplier:", _contractUnderTest.activeMultiplier());
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
        }
    }
}
