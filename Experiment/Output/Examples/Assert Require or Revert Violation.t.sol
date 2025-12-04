// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import "../src/ConditionAlwaysFalse.sol"; // Adjust path as necessary

contract ConditionAlwaysFalseTest is Test {
    ConditionAlwaysFalse public target;

    function setUp() public {
        target = new ConditionAlwaysFalse();
    }

    /**
     * @notice Tests that the updateConfiguration function ALWAYS reverts.
     * @dev We use Fuzzing (inputs id and timestamp) to try and find a value that works.
     * If the contract is working as intended (by the bad logic), it should always fail.
     */
    function test_RevertAlways_DueToImpossibleCondition(uint256 id, uint256 timestamp) public {
        ConditionAlwaysFalse.ConfigInput memory params = ConditionAlwaysFalse.ConfigInput({
            id: id,
            timestamp: timestamp
        });

        // The defect causes: require(uint < 0), which is impossible.
        // Therefore, we assert that the specific error message is always thrown.
        vm.expectRevert("Value cannot be negative");
        
        target.updateConfiguration(params);
    }
}