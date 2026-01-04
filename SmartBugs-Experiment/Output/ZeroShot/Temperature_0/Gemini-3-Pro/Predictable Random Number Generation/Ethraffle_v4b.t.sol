
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b ethraffle;

    function setUp() public {
        ethraffle = new Ethraffle_v4b();
        vm.deal(address(this), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockDifficulty, address blockCoinbase) public {
        
        // --- 1. Constraints ---
        vm.assume(blockCoinbase != address(0));
        
        // --- 2. State Configuration ---
        
        // Apply the inferred values using Cheatcodes
        vm.prevrandao(bytes32(blockDifficulty));
        vm.coinbase(blockCoinbase);

        uint256 totalTickets = ethraffle.totalTickets();
        uint256 pricePerTicket = ethraffle.pricePerTicket();

        // Buy tickets up to the last one to fill the array partially
        // We (address(this)) buy all tickets, so we control the 'contestants' array content
        for (uint256 i = 0; i < totalTickets - 1; i++) {
            ethraffle.buyTickets{value: pricePerTicket}();
        }

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally
        // Since address(this) buys all tickets (including the last one about to be bought),
        // any index lookup in 'contestants' will return address(this).
        address seed1 = address(this);
        address seed2 = address(this);
        uint256 seed3 = blockDifficulty;

        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint(expectedRandHash) % totalTickets;
                
        // Assert Predictability
        // We expect the contract to emit the result we calculated off-chain (or pre-execution)
        vm.expectEmit(false, false, false, true);
        emit Ethraffle_v4b.RaffleResult(
            1, // raffleId starts at 1
            expectedWinningNumber,
            address(this),
            seed1,
            seed2,
            seed3,
            expectedRandHash
        );

        // Execute the final purchase which triggers chooseWinner()
        ethraffle.buyTickets{value: pricePerTicket}();
    }

    receive() external payable {}
}
