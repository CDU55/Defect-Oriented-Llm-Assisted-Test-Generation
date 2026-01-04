
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
        vm.assume(uint160(blockCoinbase) > 0);
        
        // --- 2. State Configuration ---
        
        // Fund this contract to buy tickets
        vm.deal(address(this), 100 ether);
        
        // Manipulate block environment
        vm.prevrandao(bytes32(blockPrevrandao));
        vm.coinbase(blockCoinbase);

        // Buy 49 tickets first (one less than total)
        uint256 ticketsToBuy = TOTAL_TICKETS - 1;
        _contractUnderTest.buyTickets{value: ticketsToBuy * PRICE_PER_TICKET}();

        // --- 3. Replication & Assertion ---
        
        // Before buying the last ticket, predict the winning number
        // The attacker (msg.sender) will be address(this)
        
        // Replicate the vulnerable logic:
        // seed1 = contestants[uint(uint160(address(block.coinbase))) % totalTickets].addr
        // seed2 = contestants[uint(uint160(address(msg.sender))) % totalTickets].addr
        // seed3 = block.difficulty (which is block.prevrandao post-merge)
        
        uint256 seed1Index = uint256(uint160(blockCoinbase)) % TOTAL_TICKETS;
        uint256 seed2Index = uint256(uint160(address(this))) % TOTAL_TICKETS;
        
        // All tickets 0-48 are owned by address(this)
        address expectedSeed1 = address(this);
        address expectedSeed2 = address(this);
        uint256 expectedSeed3 = blockPrevrandao;
        
        bytes32 expectedRandHash = keccak256(abi.encodePacked(expectedSeed1, expectedSeed2, expectedSeed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % TOTAL_TICKETS;
        
        // Now buy the last ticket to trigger chooseWinner()
        // We expect the RaffleResult event with our predicted values
        vm.expectEmit(true, true, true, true);
        emit RaffleResult(
            1,
            expectedWinningNumber,
            address(this), // All tickets owned by this contract, so winner is this
            expectedSeed1,
            expectedSeed2,
            expectedSeed3,
            expectedRandHash
        );
        
        _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();
        
        // Verify raffle completed (raffleId incremented)
        assertEq(_contractUnderTest.raffleId(), 2, "Raffle should have completed and incremented raffleId");
    }

    receive() external payable {}
}
