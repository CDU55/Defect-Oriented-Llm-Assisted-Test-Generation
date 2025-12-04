
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract CalculatorExposed is Calculator {
    function calculateDenominator(uint256 input) public view returns (uint256) {
        return _calculateDenominator(input);
    }
}

contract TestDivisionByZeroCalculator is Test {
    CalculatorExposed calculator;

    function setUp() public {
        calculator = new CalculatorExposed();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 input) public {
        
        // --- 1. Constraints (Optional) ---

        // --- 2. State Configuration (Pre-Condition) ---

        // --- 3. Trigger & Log Strategy ---
        
        try calculator.calculateDenominator(input) returns (uint256) {

        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                
                console2.log("Input:", input);
                
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            
        }
    }
}
