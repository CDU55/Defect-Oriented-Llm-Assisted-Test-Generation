
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
        
        // --- 1. Constraints ---
        // We constrain the divisor to 100. 
        // Logic: STARTER (50) * activeMultiplier (2) = 100.
        // If the contract logic reaches subtraction: 100 - 100 = 0 (denominator).
        // If the contract has 'input / 0', any input works, but 100 is valid for both scenarios.
        vm.assume(divisor == 100);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state change needed as default multiplier is 2.

        // --- 3. Trigger & Log Strategy ---
        try calculator.divide(number, divisor) {
            // Execution Succeeded. 
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                console2.log("Divisor Input:", divisor);
                console2.log("Numerator Input:", number);
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors and ignore them.
        }
    }
}
