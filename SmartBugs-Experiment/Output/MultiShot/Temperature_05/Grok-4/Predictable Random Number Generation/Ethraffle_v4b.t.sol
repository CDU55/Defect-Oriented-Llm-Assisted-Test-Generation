
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public _contractUnderTest;
    uint256 public ticketPrice;
    address[50] public players;

    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
        ticketPrice = _contractUnderTest.pricePerTicket();
        for (uint i = 0; i < 50; i++) {
            players[i] = makeAddr(vm.toString(i));
            vm.deal(players[i], ticketPrice);
        }
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao) public {
        
        // --- 1. Constraints ---
        vm.assume(blockCoinbase != address(0));
        vm.assume(blockPrevrandao != 0);
        
        // --- 2. State Configuration ---
        
        // --- MANIPULATE BLOCK ENVIRONMENT ---
        vm.coinbase(blockCoinbase);
        vm.prevrandao(bytes32(blockPrevrandao));

        // --- 3. Replication & Assertion ---
        for (uint i = 0; i < 49; i++) {
            vm.prank(players[i]);
            _contractUnderTest.buyTickets{value: ticketPrice}();
        }

        address lastBuyer = players[49];
        uint256 totalTickets_ = _contractUnderTest.totalTickets();
        uint index1 = uint(uint160(blockCoinbase)) % totalTickets_;
        address seed1 = players[index1];
        uint index2 = uint(uint160(lastBuyer)) % totalTickets_;
        address seed2 = players[index2];
        uint seed3 = blockPrevrandao;
        bytes32 expectedHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint expectedWinningNumber = uint(expectedHash) % totalTickets_;

        vm.recordLogs();
        vm.prank(lastBuyer);
        _contractUnderTest.buyTickets{value: ticketPrice}();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2, "Should have emitted 2 events");

        Vm.Log memory resultLog = entries[1];
        (uint actualRaffleId, uint actualWinningNumber, address actualWinningAddress, address actualSeed1, address actualSeed2, uint actualSeed3, bytes32 actualRandHash) = 
            abi.decode(resultLog.data, (uint, uint, address, address, address, uint, bytes32));

        assertEq(actualWinningNumber, expectedWinningNumber, "Randomness should be predictable given block state");
    }
}
