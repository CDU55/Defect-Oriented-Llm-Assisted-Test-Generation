
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public raffle;

    function setUp() public {
        raffle = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao) public {
        
        // --- 1. Constraints ---
        vm.assume(blockCoinbase != address(0));
        vm.assume(blockPrevrandao > 0);
        
        // --- 2. State Configuration ---
        
        address buyer1 = makeAddr("buyer1");
        address buyer2 = makeAddr("buyer2");
        uint256 price = raffle.pricePerTicket();
        uint256 totalTickets = raffle.totalTickets();

        vm.deal(buyer1, (totalTickets - 1) * price);
        vm.prank(buyer1);
        raffle.buyTickets{value: (totalTickets - 1) * price}();

        // MANIPULATE BLOCK ENVIRONMENT
        vm.coinbase(blockCoinbase);
        vm.prevrandao(blockPrevrandao);

        vm.deal(buyer2, price);

        // --- 3. Replication & Assertion ---
        
        uint index1 = uint(uint160(blockCoinbase)) % totalTickets;
        address expectedSeed1 = (index1 < totalTickets - 1) ? buyer1 : buyer2;

        uint index2 = uint(uint160(buyer2)) % totalTickets;
        address expectedSeed2 = (index2 < totalTickets - 1) ? buyer1 : buyer2;

        uint expectedSeed3 = blockPrevrandao;
        bytes32 expectedRandHash = keccak256(abi.encodePacked(expectedSeed1, expectedSeed2, expectedSeed3));

        uint expectedWinningNumber = uint(expectedRandHash) % totalTickets;
        address expectedWinningAddress = (expectedWinningNumber < totalTickets - 1) ? buyer1 : buyer2;
                
        vm.expectEmit(false, false, false, true, address(raffle));
        emit Ethraffle_v4b.RaffleResult(1, expectedWinningNumber, expectedWinningAddress, expectedSeed1, expectedSeed2, expectedSeed3, expectedRandHash);

        vm.prank(buyer2);
        raffle.buyTickets{value: price}();
    }
}
