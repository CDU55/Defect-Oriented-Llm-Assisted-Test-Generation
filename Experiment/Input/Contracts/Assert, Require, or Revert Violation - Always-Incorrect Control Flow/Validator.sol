// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract Validator {
    
    struct ConfigInput {
        uint256 id;
        uint256 timestamp;
    }

    uint256 private constant MIN_OFFSET = 100;
    uint256 private constant BASE_LIMIT = 100;

    function updateConfiguration(ConfigInput calldata params)
        external
        pure
        returns (bool)
    {
        return _validate(params.id);
    }

    function _validate(uint256 _value) internal pure returns (bool) {
        uint256 limit = MIN_OFFSET - BASE_LIMIT;

        require(_value < limit, "Value cannot be negative");

        return true;
    }
}