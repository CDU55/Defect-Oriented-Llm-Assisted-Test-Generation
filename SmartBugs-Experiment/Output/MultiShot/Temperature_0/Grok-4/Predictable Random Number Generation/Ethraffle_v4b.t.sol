
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao) public {
        
        // --- 1. Constraints ---
        

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 100 ether);

        uint256 ticketPrice = _contractUnderTest.pricePerTicket();
        for (uint i = 1; i <= 49; i++) {
            address contestant = vm.addr(i);
            vm.deal(contestant, ticketPrice);
            vm.prank(contestant);
            _contractUnderTest.buyTickets{value: ticketPrice}();
        }

        vm.coinbase(blockCoinbase);
        vm.prevrandao(bytes32(blockPrevrandao));

        // --- 3. Replication & Assertion ---
        
        address buyer = vm.addr(100);
        vm.deal(buyer, ticketPrice);

        address[50] memory localContestants;
        for (uint i = 0; i < 49; i++) {
            localContestants[i] = vm.addr(i + 1);
        }
        localContestants[49] = buyer;

        uint index1 = uint(uint160(blockCoinbase)) % 50;
        address seed1 = localContestants[index1];

        uint index2 = uint(uint160(buyer)) % 50;
        address seed2 = localContestants[index2];

        uint seed3 = blockPrevrandao;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));

        uint winningNumber = uint(randHash) % 50;
        address winningAddress = localContestants[winningNumber];

        vm.expectEmit(true, true, true, true, address(_contractUnderTest));
        emit Ethraffle_v4b.RaffleResult(1, winningNumber, winningAddress, seed1, seed2, seed3, randHash);

        vm.prank(buyer);
        _contractUnderTest.buyTickets{value: ticketPrice}();
    }
}
