
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public raffle;
    uint256 public constant PRICE_PER_TICKET = (2.5 ether + 0.03 ether) / 50;

    function setUp() public {
        raffle = new Ethraffle_v4b();
        vm.deal(address(this), 100 ether);
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao, address buyer) public {
        vm.assume(buyer != address(0));
        vm.assume(blockCoinbase != address(0));
        
        vm.coinbase(blockCoinbase);
        vm.prevrandao(bytes32(blockPrevrandao));

        for (uint256 i = 0; i < 49; i++) {
            address contestant = address(uint160(i + 1));
            vm.deal(contestant, PRICE_PER_TICKET);
            vm.prank(contestant);
            raffle.buyTickets{value: PRICE_PER_TICKET}();
        }

        uint256 ticketIndexCoinbase = uint256(uint160(blockCoinbase)) % 50;
        address seed1 = address(uint160(ticketIndexCoinbase + 1));
        
        address seed2 = buyer;
        uint256 seed3 = blockPrevrandao;
        
        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % 50;

        vm.deal(buyer, PRICE_PER_TICKET);
        vm.prank(buyer);
        raffle.buyTickets{value: PRICE_PER_TICKET}();
    }

    receive() external payable {}

    fallback() external payable {}
}
