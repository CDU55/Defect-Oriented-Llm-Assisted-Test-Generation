
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b raffle;

    address attacker = address(0xA11CE);
    address miner1 = address(0xBEEF);
    address miner2 = address(0xCAFE);

    function setUp() public {
        vm.deal(attacker, 100 ether);
        vm.deal(miner1, 100 ether);
        vm.deal(miner2, 100 ether);

        vm.prank(attacker);
        raffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(
        uint256 blockDifficulty,
        bool useMiner1
    ) public {
        vm.assume(blockDifficulty > 0 && blockDifficulty < type(uint64).max);

        address chosenCoinbase = useMiner1 ? miner1 : miner2;
        vm.coinbase(chosenCoinbase);
        vm.prevrandao(bytes32(uint256(0x1234))); // not used but keeps env consistent
        vm.roll(100);
        vm.warp(1 hours);

        uint256 pricePerTicket = raffle.pricePerTicket();
        uint256 totalTickets = raffle.totalTickets();

        vm.startPrank(attacker);
        raffle.buyTickets{value: pricePerTicket * totalTickets}();
        vm.stopPrank();

        vm.difficulty(blockDifficulty);

        address seed1 = attacker;
        address seed2 = attacker;
        uint256 seed3 = blockDifficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(randHash) % totalTickets;

        vm.expectEmit(true, true, true, true);
        emit Ethraffle_v4b.RaffleResult(
            raffle.raffleId(),
            expectedWinningNumber,
            attacker,
            seed1,
            seed2,
            seed3,
            randHash
        );

        vm.prank(attacker);
        raffle.buyTickets{value: 0}();
    }
}
