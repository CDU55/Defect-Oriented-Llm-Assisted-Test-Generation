
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b raffle;

    function setUp() public {
        raffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao) public {
        
        // --- 1. Constraints ---
        
        
        

        // --- 2. State Configuration ---
        
        address[50] memory players;
        for (uint i = 0; i < 50; i++) {
            players[i] = makeAddr(string.concat("player", vm.toString(i)));
            vm.deal(players[i], 1 ether);
        }

        uint256 price = raffle.pricePerTicket();

        for (uint i = 0; i < 49; i++) {
            vm.prank(players[i]);
            raffle.buyTickets{value: price}();
        }
        
        vm.coinbase(blockCoinbase);
        vm.prevrandao(blockPrevrandao);

        // --- 3. Replication & Assertion ---
        
        uint256 total = 50;
        uint256 currentRaffleId = raffle.raffleId();

        address seed1 = players[uint(uint160(blockCoinbase)) % total];
        address seed2 = players[uint(uint160(players[49])) % total];
        uint256 seed3 = blockPrevrandao;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));

        uint256 expectedWinningNumber = uint(randHash) % total;
        address expectedWinner = players[expectedWinningNumber];
        
        vm.expectEmit(true, true, true, true);
        emit Ethraffle_v4b.RaffleResult(currentRaffleId, expectedWinningNumber, expectedWinner, seed1, seed2, seed3, randHash);
        
        vm.prank(players[49]);
        raffle.buyTickets{value: price}();
        
    }
}
