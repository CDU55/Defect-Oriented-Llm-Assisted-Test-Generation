
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
        
        // --- 1. Constraints (Optional) ---

        // --- 2. State Configuration (Pre-Condition) ---

        // --- 3. Trigger & Log Strategy ---
        
        try this.divideWrapper(number, divisor) {
            
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                
                console2.log("number:", number);
                console2.log("divisor:", divisor);
                
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            
        }
    }

    // Wrapper to make the call external for try-catch
    function divideWrapper(uint256 number, uint256 divisor) external view {
        calculator.divide(number, divisor);
    }
}
