
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
        vm.deal(address(this), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockPrevrandao, address blockCoinbase) public {
        
        // --- 1. Constraints ---
        vm.assume(blockCoinbase != address(0));
        
        // --- 2. State Configuration ---
        vm.prevrandao(bytes32(blockPrevrandao));
        vm.coinbase(blockCoinbase);

        uint256 pricePerTicket = _contractUnderTest.pricePerTicket();
        uint256 totalTickets = _contractUnderTest.totalTickets();

        // Buy tickets to fill the raffle up to the last one (49 tickets)
        // We buy them all from this contract, so contestants[0...48] = address(this)
        _contractUnderTest.buyTickets{value: pricePerTicket * (totalTickets - 1)}();

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        // We are about to buy the 50th ticket.
        // Since we bought all tickets from address(this), all contestants in the mapping will be address(this).
        // Therefore, regardless of the index derived from coinbase or msg.sender, the address retrieved is address(this).
        address seed1 = address(this); 
        address seed2 = address(this);
        uint256 seed3 = blockPrevrandao; // Corresponds to block.difficulty

        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % totalTickets;

        // EXECUTE
        // We record logs to verify the internal calculation emitted in the event
        vm.recordLogs();
        _contractUnderTest.buyTickets{value: pricePerTicket}();

        // ASSERT PREDICTABILITY
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool eventFound = false;
        // Event signature: RaffleResult(uint256,uint256,address,address,address,uint256,bytes32)
        bytes32 eventSig = keccak256("RaffleResult(uint256,uint256,address,address,address,uint256,bytes32)");

        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == eventSig) {
                (
                    , // raffleId
                    uint winningNumber,
                    , // winningAddress
                    , // seed1
                    , // seed2
                    , // seed3
                    bytes32 randHash
                ) = abi.decode(entries[i].data, (uint, uint, address, address, address, uint, bytes32));

                assertEq(winningNumber, expectedWinningNumber, "Winning number should be predictable given block state");
                assertEq(randHash, expectedRandHash, "Random hash should be predictable given block state");
                eventFound = true;
            }
        }
        assertTrue(eventFound, "RaffleResult event should have been emitted");
    }

    receive() external payable {}
}
