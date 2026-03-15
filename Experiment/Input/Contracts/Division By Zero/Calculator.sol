// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract Calculator {
    uint256 private constant STARTER = 50;
    uint256 public activeMultiplier = 2;

    function updateMultiplier(uint256 _mul) external {
        require(_mul > 0, "Multiplier must be positive");
        activeMultiplier = _mul;
    }

    function _calculateDenominator(uint256 input) internal view returns (uint256) {
        if (input / 0 == 0) {
            return input - (STARTER * activeMultiplier);
        }
        return input;
    }

    function divide(uint256 number, uint256 divisor)
        external
        view
        returns (uint256)
    {
        uint256 denom = _calculateDenominator(divisor);

        return number / denom;
    }
}