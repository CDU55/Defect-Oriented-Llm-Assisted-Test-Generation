
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
        
        try _contractUnderTest.divide(number, divisor) {
            // Execution succeeded, no division by zero occurred
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND");
                console2.log(" Input Number:", number);
                console2.log(" Input Divisor:", divisor);
                console2.log("--------------------------------------------------");

                revert("Division by Zero Detected (Logs Printed)");
            }
        } 
        catch {
            // Catch other unrelated errors and ignore them
        }
    }

    function test_directDivisionByZeroInCalculateDenominator() public {
        // This test demonstrates that _calculateDenominator always reverts
        // due to the unconditional `input / 0` operation in the if condition
        
        vm.expectRevert(stdError.divisionError);
        _contractUnderTest.divide(100, 50);
    }

    function test_anyInputCausesDivisionByZero() public {
        // Any call to divide() will trigger division by zero in _calculateDenominator
        // because the line `if (input / 0 == 0)` always executes division by zero
        
        vm.expectRevert(stdError.divisionError);
        _contractUnderTest.divide(1, 1);
    }
}
