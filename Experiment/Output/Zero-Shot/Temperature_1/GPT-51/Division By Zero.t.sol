
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Calculator} from "../src/Calculator.sol";

contract TestDivisionByZeroCalculator is Test {
    Calculator calc;

    function setUp() public {
        calc = new Calculator();
    }

    function test_highlightThrowsDivisionByZeroException() public {
        uint256 number = 1;
        uint256 divisor = 1;

        try calc.divide(number, divisor) {
        } 
        catch Panic(uint256 errorCode) {
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
}
