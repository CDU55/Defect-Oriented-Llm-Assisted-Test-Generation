
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, Vm} from "forge-std/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao) public {
        
        // --- 1. Constraints ---
        

        // --- 2. State Configuration ---
        

        // --- 3. Replication & Assertion ---
        
        uint256 totalTickets = _contractUnderTest.totalTickets();
        uint256 pricePerTicket = _contractUnderTest.pricePerTicket();
        uint256 prize = _contractUnderTest.prize();

        address[] memory players = new address[](totalTickets);
        for (uint256 i = 0; i < totalTickets; i++) {
            players[i] = vm.addr(i + 1);
            vm.deal(players[i], pricePerTicket * 2);
        }

        // Buy first 49 tickets
        for (uint256 i = 0; i < totalTickets - 1; i++) {
            vm.prank(players[i]);
            _contractUnderTest.buyTickets{value: pricePerTicket}();
        }

        vm.coinbase(blockCoinbase);
        vm.prevrandao(bytes32(blockPrevrandao));

        address lastSender = players[totalTickets - 1];
        address seed1 = players[uint256(uint160(blockCoinbase)) % totalTickets];
        address seed2 = players[uint256(uint160(lastSender)) % totalTickets];
        uint256 seed3 = blockPrevrandao;
        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % totalTickets;

        vm.recordLogs();
        vm.prank(lastSender);
        _contractUnderTest.buyTickets{value: pricePerTicket}();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 2, "Should have emitted two events");

        (uint256 actualRaffleId, uint256 actualWinningNumber, address actualWinningAddress,
         address actualSeed1, address actualSeed2, uint256 actualSeed3, bytes32 actualRandHash) =
            abi.decode(entries[1].data, (uint256, uint256, address, address, address, uint256, bytes32));

        assertEq(actualWinningNumber, expectedWinningNumber, "Randomness should be predictable given block state");
    }
}
