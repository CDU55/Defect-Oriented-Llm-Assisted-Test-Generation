
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
        
        

        
        vm.coinbase(blockCoinbase);
        vm.prevrandao(blockPrevrandao);

        // --- 3. Replication & Assertion ---
        
        address[50] memory buyers;
        for (uint256 i = 0; i < 49; i++) {
            buyers[i] = address(uint160(i + 1));
            vm.deal(buyers[i], raffle.pricePerTicket());
            vm.prank(buyers[i]);
            raffle.buyTickets{value: raffle.pricePerTicket()}();
        }
        buyers[49] = address(uint160(50));
        vm.deal(buyers[49], raffle.pricePerTicket());

        uint256 index1 = uint256(uint160(blockCoinbase)) % 50;
        address seed1 = buyers[index1];

        uint256 index2 = uint256(uint160(buyers[49])) % 50;
        address seed2 = buyers[index2];

        uint256 seed3 = blockPrevrandao;

        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 winningNumber = uint256(randHash) % 50;
        address winningAddress = buyers[winningNumber];

        vm.expectEmit(true, true, true, true, address(raffle));
        emit Ethraffle_v4b.RaffleResult(1, winningNumber, winningAddress, seed1, seed2, seed3, randHash);

        vm.prank(buyers[49]);
        raffle.buyTickets{value: raffle.pricePerTicket()}();
    }
}
