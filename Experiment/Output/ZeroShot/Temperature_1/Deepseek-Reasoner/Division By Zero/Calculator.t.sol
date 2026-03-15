// Generation Time: 70,45s
// Input Tokens: 1840
// Output Tokens: 317
// Reasoning Tokens: 2770


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator public calculator;

    function setUp() public {
        calculator = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 number, uint256 divisor) public {
        vm.assume(divisor > 0 && divisor <= 100);
        
        uint256 denom = divisor - (50 * calculator.activeMultiplier());
        
        vm.assume(divisor == 50 * calculator.activeMultiplier());

        try calculator.divide(number, divisor) {
            
        } 
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                console2.log("     Input divisor:", divisor);
                console2.log("     Computed denominator:", denom);
                console2.log("     Active multiplier:", calculator.activeMultiplier());
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
            
        }
    }
}
