
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public raffle;

    function setUp() public {
        raffle = new Ethraffle_v4b();
        vm.deal(address(this), 500 ether);
        vm.deal(address(raffle), 500 ether);
    }

    function test_highlightPredictableRandomValue(
        uint256 blockNumber,
        uint256 blockPrevrandao,
        address blockCoinbase
    ) public {
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint256).max);
        vm.assume(blockPrevrandao > 0);
        vm.assume(blockPrevrandao < type(uint256).max);

        vm.roll(blockNumber);
        vm.prevrandao(bytes32(blockPrevrandao));
        vm.coinbase(blockCoinbase);

        uint256 pricePerTicket = (raffle.prize() + raffle.fee()) / raffle.totalTickets();

        for (uint256 i = 0; i < raffle.totalTickets(); i++) {
            raffle.buyTickets{value: pricePerTicket}();
        }

        uint256 totalTickets = raffle.totalTickets();
        Ethraffle_v4b.Contestant memory seed1Contestant =
            getContestant(address(raffle), uint(uint160(address(block.coinbase))) % totalTickets);
        Ethraffle_v4b.Contestant memory seed2Contestant =
            getContestant(address(raffle), uint(uint160(address(this))) % totalTickets);

        address seed1 = seed1Contestant.addr;
        address seed2 = seed2Contestant.addr;
        uint256 seed3 = block.difficulty;

        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(randHash) % totalTickets;

        vm.expectEmit(false, false, false, true);
        emit Ethraffle_v4b.RaffleResult(
            raffle.raffleId(),
            expectedWinningNumber,
            getContestant(address(raffle), expectedWinningNumber).addr,
            seed1,
            seed2,
            seed3,
            randHash
        );

        vm.roll(blockNumber + 1);
        vm.prevrandao(bytes32(blockPrevrandao));
        vm.coinbase(blockCoinbase);

        vm.expectRevert();
        raffle.buyTickets{value: pricePerTicket}();
    }

    function getContestant(address raffleAddr, uint256 index) internal view returns (Ethraffle_v4b.Contestant memory) {
        bytes32 slot = keccak256(abi.encode(index, uint256(5)));
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        address addr = address(uint160(uint256(value)));
        uint256 raffleId = uint256(value >> 160);
        return Ethraffle_v4b.Contestant(addr, raffleId);
    }
}
