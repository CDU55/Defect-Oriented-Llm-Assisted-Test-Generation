
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator public calculator;

    function setUp() public {
        calculator = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException(uint256 number, uint256 divisor) public {
        
        try calculator.divide(number, divisor) {
        } 
        catch Panic(uint256 errorCode) {
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                
                console2.log(" Number:", number);
                console2.log(" Divisor:", divisor);
                
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
        }
    }
}
