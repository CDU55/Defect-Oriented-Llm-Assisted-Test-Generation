// Generation Time: 12,81s
// Input Tokens: 1521
// Output Tokens: 413
// Reasoning Tokens: 1752


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator public _contractUnderTest;

    uint256 internal constant STARTER = 50;

    function setUp() public {
        _contractUnderTest = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 multiplier, uint256 number) public {
        // Constrain fuzz parameters to avoid overflow in STARTER * multiplier
        vm.assume(multiplier > 0 && multiplier < type(uint256).max / STARTER);
        vm.assume(number > 0);

        _contractUnderTest.updateMultiplier(multiplier);

        // This value will make the internal denominator equal to zero:
        // denom = input - (STARTER * activeMultiplier)
        // where input == divisor and activeMultiplier == multiplier
        uint256 divisor = STARTER * multiplier;

        try _contractUnderTest.divide(number, divisor) returns (uint256 result) {
            console2.log("Call succeeded unexpectedly with result:", result);
        } 
        catch Panic(uint256 errorCode) {
            // Panic code 0x12 = division or modulo by zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log(" Multiplier:", multiplier);
                console2.log(" Number:", number);
                console2.log(" Divisor (user-controlled):", divisor);
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
            // Ignore other errors
        }
    }
}
