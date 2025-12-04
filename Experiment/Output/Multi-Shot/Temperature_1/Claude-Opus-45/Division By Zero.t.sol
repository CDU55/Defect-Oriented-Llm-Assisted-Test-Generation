
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
        // --- 1. Constraints ---
        vm.assume(number < type(uint128).max);
        vm.assume(divisor < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No additional state configuration needed - the vulnerability exists
        // in _calculateDenominator which always divides by zero (input / 0)

        // --- 3. Trigger & Log Strategy ---
        try _contractUnderTest.divide(number, divisor) {
            // Execution succeeded - no division by zero occurred
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                console2.log(" Input Number:", number);
                console2.log(" Input Divisor:", divisor);
                console2.log(" Active Multiplier:", _contractUnderTest.activeMultiplier());
                console2.log("--------------------------------------------------");

                // Force the test to fail to stop the Fuzzer and display logs
                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors and ignore them
        }
    }

    function test_directDivisionByZeroInCalculateDenominator() public {
        // This test directly proves the division by zero vulnerability
        // The _calculateDenominator function contains: if (input / 0 == 0)
        // This will ALWAYS cause a division by zero panic regardless of input
        
        uint256 number = 100;
        uint256 divisor = 50;

        vm.expectRevert(stdError.divisionError);
        _contractUnderTest.divide(number, divisor);
    }
}
