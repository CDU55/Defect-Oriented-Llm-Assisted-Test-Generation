
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public luckyDoubler;

    function setUp() public {
        luckyDoubler = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        // --- 1. Constraints ---
        blockNumber = bound(blockNumber, 1, 1000);

        // --- 2. State Configuration ---
        vm.deal(address(this), 5 ether);

        // --- 3. Manipulate Block Environment ---
        vm.roll(blockNumber);

        // --- 4. Replication & Assertion ---
        uint256 lastBlockNumber = blockNumber - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / 2;
        uint256 expectedResult = uint256((uint256(hashVal) / factor)) % 2;

        uint256 actualResult = luckyDoubler.rand(2);

        assertEq(actualResult, expectedResult);
    }
}
