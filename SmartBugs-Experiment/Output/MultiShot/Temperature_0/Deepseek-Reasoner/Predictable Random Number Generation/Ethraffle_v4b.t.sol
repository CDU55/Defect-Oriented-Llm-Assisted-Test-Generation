
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public _contractUnderTest;
    uint256 public constant TOTAL_TICKETS = 50;
    uint256 public constant PRICE_PER_TICKET = (2.5 ether + 0.03 ether) / TOTAL_TICKETS;

    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao) public {
        vm.assume(blockCoinbase != address(0));
        
        vm.deal(address(this), 100 ether);
        
        vm.coinbase(blockCoinbase);
        vm.prevrandao(bytes32(blockPrevrandao));

        for (uint256 i = 0; i < TOTAL_TICKETS - 1; i++) {
            _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();
        }

        address seed1 = address(this);
        address seed2 = address(this);
        uint256 seed3 = blockPrevrandao;
        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % TOTAL_TICKETS;

        uint256 snapshot = vm.snapshot();
        
        vm.expectEmit(true, true, true, true);
        emit Ethraffle_v4b.RaffleResult(
            1,
            expectedWinningNumber,
            address(this),
            address(this),
            address(this),
            seed3,
            expectedRandHash
        );
        
        _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();
        
        vm.revertTo(snapshot);
        
        vm.expectEmit(true, true, true, true);
        emit Ethraffle_v4b.RaffleResult(
            1,
            expectedWinningNumber,
            address(this),
            address(this),
            address(this),
            seed3,
            expectedRandHash
        );
        
        _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();
    }
}
