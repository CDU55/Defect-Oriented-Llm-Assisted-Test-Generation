// Generation Time: 67,83s
// Input Tokens: 1840
// Output Tokens: 340
// Reasoning Tokens: 2619


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
        
        vm.assume(divisor >= 50 * 2);
        vm.assume(divisor <= 50 * 2 + type(uint256).max - 100);
        
        try calculator.divide(number, divisor) {
            
        } 
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log("  [*] Inputs: number = %s, divisor = %s", number, divisor);
                console2.log("  [*] Denominator after _calculateDenominator: 0");
                console2.log("  [*] STARTER * activeMultiplier = %s", 50 * calculator.activeMultiplier());
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
            
        }
    }
}
