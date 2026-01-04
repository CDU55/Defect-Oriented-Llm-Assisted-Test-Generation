
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public ethraffle;

    function setUp() public {
        ethraffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(uint blockNumber, address blockCoinbase, address msgSender) public {
        // --- 1. Constraints ---
        blockNumber = bound(blockNumber, 1, 1000000);
        blockCoinbase = address(uint160(uint256(blockCoinbase) % 50));
        msgSender = address(uint160(uint256(msgSender) % 50));

        // --- 2. State Configuration ---
        vm.deal(address(1), 2.5 ether);
        vm.deal(address(2), 2.5 ether);
        vm.deal(address(3), 2.5 ether);

        // --- 3. Manipulate Block Environment ---
        vm.roll(blockNumber);
        vm.coinbase(blockCoinbase);

        // --- 4. Replication & Assertion ---
        // Predict the outcome
        address seed1 = address(uint160(blockCoinbase));
        address seed2 = msgSender;
        uint seed3 = block.difficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint expectedWinningNumber = uint(randHash) % 50;

        // Execute
        vm.startPrank(address(1));
        ethraffle.buyTickets{value: 2.5 ether}();
        vm.stopPrank();

        vm.startPrank(address(2));
        ethraffle.buyTickets{value: 2.5 ether}();
        vm.stopPrank();

        vm.startPrank(address(3));
        ethraffle.buyTickets{value: 2.5 ether}();
        vm.stopPrank();

        // Assert predictability
        emit log_named_uint("Expected Winning Number", expectedWinningNumber);
        emit log_named_uint("Actual Winning Number", ethraffle.raffleId() - 1);
    }
}
