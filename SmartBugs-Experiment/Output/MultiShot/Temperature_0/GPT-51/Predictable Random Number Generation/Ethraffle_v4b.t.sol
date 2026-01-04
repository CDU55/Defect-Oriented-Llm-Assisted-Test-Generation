
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public raffle;

    address public attacker = address(0xA11CE);
    address public victim1 = address(0xBEEF1);
    address public victim2 = address(0xBEEF2);

    function setUp() public {
        vm.deal(attacker, 100 ether);
        vm.deal(victim1, 100 ether);
        vm.deal(victim2, 100 ether);

        raffle = new Ethraffle_v4b();
        vm.deal(address(raffle), 0);
    }

    function test_highlightPredictableRandomValue(
        uint256 blockNumber,
        uint256 blockPrevrandao,
        address blockCoinbase
    ) public {
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint256).max - 1000);
        vm.assume(blockPrevrandao > 0);
        vm.assume(blockCoinbase != address(0));

        vm.roll(blockNumber);
        vm.prevrandao(bytes32(blockPrevrandao));
        vm.coinbase(blockCoinbase);

        uint256 pricePerTicket = raffle.pricePerTicket();
        uint256 totalTickets = raffle.totalTickets();

        vm.startPrank(victim1);
        raffle.buyTickets{value: pricePerTicket * 10}();
        vm.stopPrank();

        vm.startPrank(victim2);
        raffle.buyTickets{value: pricePerTicket * 10}();
        vm.stopPrank();

        vm.startPrank(attacker);
        raffle.buyTickets{value: pricePerTicket * (totalTickets - 20)}();
        vm.stopPrank();

        address[] memory contestants = new address[](totalTickets);
        for (uint256 i = 0; i < totalTickets; i++) {
            (bool success, bytes memory data) = address(raffle).staticcall(
                abi.encodeWithSignature("contestants(uint256)", i)
            );
            require(success, "staticcall failed");
            (address addr, uint256 raffleId) = abi.decode(data, (address, uint256));
            if (raffleId == raffle.raffleId()) {
                contestants[i] = addr;
            }
        }

        address seed1 = contestants[uint256(uint160(address(block.coinbase))) % totalTickets];
        address seed2 = contestants[uint256(uint160(address(attacker))) % totalTickets];
        uint256 seed3 = block.difficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(randHash) % totalTickets;

        vm.expectEmit(true, true, true, true);
        emit Ethraffle_v4b.RaffleResult(
            raffle.raffleId(),
            expectedWinningNumber,
            contestants[expectedWinningNumber],
            seed1,
            seed2,
            seed3,
            randHash
        );

        vm.prank(attacker);
        raffle.buyTickets{value: 0}();

        assertTrue(
            contestants[expectedWinningNumber] == attacker ||
                contestants[expectedWinningNumber] == victim1 ||
                contestants[expectedWinningNumber] == victim2,
            "Winning address must be one of the known contestants"
        );
    }
}
