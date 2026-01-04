
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public _contractUnderTest;
    
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
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(uint256 blockPrevrandao, address blockCoinbase) public {
        
        // --- 1. Constraints ---
        vm.assume(blockCoinbase != address(0));
        vm.assume(blockPrevrandao > 0);
        
        // --- 2. State Configuration ---
        vm.deal(address(this), 100 ether);
        
        // Manipulate block environment
        vm.prevrandao(bytes32(blockPrevrandao));
        vm.coinbase(blockCoinbase);

        // --- 3. Buy tickets to fill the raffle ---
        // We need to buy 49 tickets first, then predict the winner before buying the last one
        
        // Create multiple addresses to buy tickets
        address[] memory buyers = new address[](49);
        for (uint256 i = 0; i < 49; i++) {
            buyers[i] = address(uint160(i + 1));
            vm.deal(buyers[i], PRICE_PER_TICKET);
            vm.prank(buyers[i]);
            _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();
        }

        // Now we have 49 tickets sold. The 50th ticket purchase will trigger chooseWinner()
        // We can predict the outcome before buying the last ticket
        
        address lastBuyer = address(uint160(100));
        vm.deal(lastBuyer, PRICE_PER_TICKET);

        // --- 4. Predict the outcome ---
        // Replicate the vulnerable logic from chooseWinner()
        
        // After last buyer purchases, they become contestant[49]
        // seed1 = contestants[uint(uint160(block.coinbase)) % totalTickets].addr
        uint256 seed1Index = uint256(uint160(blockCoinbase)) % TOTAL_TICKETS;
        address predictedSeed1;
        if (seed1Index < 49) {
            predictedSeed1 = buyers[seed1Index];
        } else {
            // Index 49 will be the lastBuyer
            predictedSeed1 = lastBuyer;
        }
        
        // seed2 = contestants[uint(uint160(msg.sender)) % totalTickets].addr
        uint256 seed2Index = uint256(uint160(lastBuyer)) % TOTAL_TICKETS;
        address predictedSeed2;
        if (seed2Index < 49) {
            predictedSeed2 = buyers[seed2Index];
        } else {
            predictedSeed2 = lastBuyer;
        }
        
        // seed3 = block.difficulty (which is block.prevrandao post-merge)
        uint256 predictedSeed3 = blockPrevrandao;
        
        // Calculate the expected random hash
        bytes32 predictedRandHash = keccak256(abi.encodePacked(predictedSeed1, predictedSeed2, predictedSeed3));
        
        // Calculate expected winning number
        uint256 expectedWinningNumber = uint256(predictedRandHash) % TOTAL_TICKETS;
        
        // Determine expected winner address
        address expectedWinner;
        if (expectedWinningNumber < 49) {
            expectedWinner = buyers[expectedWinningNumber];
        } else {
            expectedWinner = lastBuyer;
        }

        // --- 5. Execute and capture the actual result ---
        vm.expectEmit(true, true, true, true);
        emit RaffleResult(
            1,
            expectedWinningNumber,
            expectedWinner,
            predictedSeed1,
            predictedSeed2,
            predictedSeed3,
            predictedRandHash
        );
        
        vm.prank(lastBuyer);
        _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();

        // --- 6. Assert Predictability ---
        // The raffle ID should have incremented, proving the raffle completed
        assertEq(_contractUnderTest.raffleId(), 2, "Raffle should have completed and incremented raffleId");
        
        // The expected winner should have received the prize
        // Initial balance was PRICE_PER_TICKET, spent it on ticket
        // If they won, they received 2.5 ether prize
        if (expectedWinner != lastBuyer) {
            assertGe(expectedWinner.balance, 2.5 ether, "Predicted winner should have received the prize");
        }
    }

    receive() external payable {}
}
