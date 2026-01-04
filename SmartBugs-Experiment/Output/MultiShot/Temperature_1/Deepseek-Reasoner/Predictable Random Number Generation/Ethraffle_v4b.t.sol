
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao, address caller) public {
        vm.assume(caller != address(0));
        vm.assume(blockCoinbase != address(0));
        vm.assume(blockPrevrandao > 0);

        vm.deal(address(this), 100 ether);
        vm.coinbase(blockCoinbase);
        vm.prevrandao(bytes32(blockPrevrandao));

        uint256 pricePerTicket = _contractUnderTest.pricePerTicket();
        uint256 totalCost = pricePerTicket * 50;

        for (uint256 i = 0; i < 50; i++) {
            _contractUnderTest.buyTickets{value: pricePerTicket}();
        }

        vm.prank(caller);
        _contractUnderTest.buyTickets{value: pricePerTicket}();

        uint256 index1 = uint256(uint160(blockCoinbase)) % 50;
        uint256 index2 = uint256(uint160(caller)) % 50;
        
        address seed1Addr = address(this);
        address seed2Addr = caller;
        uint256 seed3 = blockPrevrandao;
        
        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1Addr, seed2Addr, seed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % 50;

        vm.expectEmit(true, true, true, true);
        emit RaffleResult(
            1,
            expectedWinningNumber,
            address(this),
            seed1Addr,
            seed2Addr,
            seed3,
            expectedRandHash
        );

        _contractUnderTest.buyTickets{value: totalCost}();
    }

    event RaffleResult(
        uint raffleId,
        uint winningNumber,
        address winningAddress,
        address seed1,
        address seed2,
        uint seed3,
        bytes32 randHash
    );
}
