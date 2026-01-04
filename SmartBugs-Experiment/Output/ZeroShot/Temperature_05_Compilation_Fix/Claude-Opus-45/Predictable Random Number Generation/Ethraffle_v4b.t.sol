
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public raffle;
    
    uint256 public constant TOTAL_TICKETS = 50;
    uint256 public constant PRICE_PER_TICKET = (2.5 ether + 0.03 ether) / 50;

    event RaffleResult(
        uint raffleId,
        uint winningNumber,
        address winningAddress,
        address seed1,
        address seed2,
        uint seed3,
        bytes32 randHash
    );

    function setUp() public {
        raffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(
        address blockCoinbase,
        uint256 blockDifficulty
    ) public {
        
        // --- 1. Constraints ---
        vm.assume(blockCoinbase != address(0));
        vm.assume(blockDifficulty > 0 && blockDifficulty < type(uint128).max);

        // --- 2. State Configuration ---
        
        // Create multiple buyers to fill tickets
        address[] memory buyers = new address[](TOTAL_TICKETS);
        for (uint256 i = 0; i < TOTAL_TICKETS; i++) {
            buyers[i] = address(uint160(i + 1));
            vm.deal(buyers[i], PRICE_PER_TICKET);
        }

        // Buy 49 tickets first (one ticket per buyer for simplicity)
        for (uint256 i = 0; i < TOTAL_TICKETS - 1; i++) {
            vm.prank(buyers[i]);
            raffle.buyTickets{value: PRICE_PER_TICKET}();
        }

        // Set up the block environment before the final ticket purchase
        vm.coinbase(blockCoinbase);
        vm.difficulty(blockDifficulty);

        // The attacker (last buyer) will purchase the final ticket
        address attacker = buyers[TOTAL_TICKETS - 1];
        vm.deal(attacker, PRICE_PER_TICKET);

        // --- 3. Replication & Assertion ---
        
        // Predict the outcome using the same logic as chooseWinner()
        // seed1 = contestants[uint(uint160(address(block.coinbase))) % totalTickets].addr
        uint256 seed1Index = uint256(uint160(blockCoinbase)) % TOTAL_TICKETS;
        address predictedSeed1 = buyers[seed1Index];
        
        // seed2 = contestants[uint(uint160(address(msg.sender))) % totalTickets].addr
        uint256 seed2Index = uint256(uint160(attacker)) % TOTAL_TICKETS;
        address predictedSeed2 = buyers[seed2Index];
        
        // seed3 = block.difficulty
        uint256 predictedSeed3 = blockDifficulty;
        
        // Calculate the predicted random hash
        bytes32 predictedRandHash = keccak256(abi.encodePacked(predictedSeed1, predictedSeed2, predictedSeed3));
        
        // Calculate the predicted winning number
        uint256 predictedWinningNumber = uint256(predictedRandHash) % TOTAL_TICKETS;
        
        // The predicted winner address
        address predictedWinner = buyers[predictedWinningNumber];

        // Record the winner's balance before
        uint256 winnerBalanceBefore = predictedWinner.balance;

        // Expect the RaffleResult event with our predicted values
        vm.expectEmit(true, true, true, true);
        emit RaffleResult(
            1,
            predictedWinningNumber,
            predictedWinner,
            predictedSeed1,
            predictedSeed2,
            predictedSeed3,
            predictedRandHash
        );

        // Execute the final ticket purchase which triggers chooseWinner()
        vm.prank(attacker);
        raffle.buyTickets{value: PRICE_PER_TICKET}();

        // Assert that the predicted winner received the prize
        uint256 winnerBalanceAfter = predictedWinner.balance;
        
        // The winner should have received the prize (2.5 ether)
        // Account for the case where winner is also the attacker (last buyer)
        if (predictedWinner == attacker) {
            // Attacker spent PRICE_PER_TICKET but won 2.5 ether
            assertEq(
                winnerBalanceAfter,
                winnerBalanceBefore - PRICE_PER_TICKET + 2.5 ether,
                "Predicted winner (attacker) should have received the prize"
            );
        } else {
            assertEq(
                winnerBalanceAfter,
                winnerBalanceBefore + 2.5 ether,
                "Predicted winner should have received the prize"
            );
        }

        // Verify raffle moved to next round
        assertEq(raffle.raffleId(), 2, "Raffle should have moved to round 2");
    }
}
