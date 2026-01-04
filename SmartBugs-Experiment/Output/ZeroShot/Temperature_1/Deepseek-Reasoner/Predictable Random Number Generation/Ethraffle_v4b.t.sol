
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public raffle;
    address constant buyer = address(0x1234);
    uint256 constant TICKET_PRICE = 0.0506 ether;
    uint256 constant TOTAL_COST = 50 * TICKET_PRICE;

    function setUp() public {
        raffle = new Ethraffle_v4b();
        vm.deal(buyer, TOTAL_COST);
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, address lastBuyer, uint256 blockPrevrandao) public {
        vm.assume(blockCoinbase != address(0));
        vm.assume(lastBuyer != address(0));
        vm.assume(uint256(uint160(blockCoinbase)) % 50 < 50);
        vm.assume(uint256(uint160(lastBuyer)) % 50 < 50);

        vm.coinbase(blockCoinbase);
        vm.prank(buyer);
        raffle.buyTickets{value: TOTAL_COST - TICKET_PRICE}();

        vm.prank(lastBuyer);
        raffle.buyTickets{value: TICKET_PRICE}();

        address seed1 = address(uint160(uint256(uint160(blockCoinbase)) % 50));
        address seed2 = address(uint160(uint256(uint160(lastBuyer)) % 50));
        uint256 seed3 = blockPrevrandao;
        vm.prevrandao(bytes32(blockPrevrandao));

        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % 50;

        vm.recordLogs();
        vm.prank(lastBuyer);
        raffle.buyTickets{value: 0}();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("RaffleResult(uint256,uint256,address,address,address,uint256,bytes32)")) {
                (uint256 raffleId, uint256 winningNumber, , , , , ) = abi.decode(
                    entries[i].data,
                    (uint256, uint256, address, address, address, uint256, bytes32)
                );
                if (raffleId == 1) {
                    assertEq(winningNumber, expectedWinningNumber);
                    return;
                }
            }
        }
        revert("RaffleResult event not found");
    }
}
