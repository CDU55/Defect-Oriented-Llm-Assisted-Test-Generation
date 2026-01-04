
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, address blockCoinbase) public {
        vm.assume(blockNumber >= block.number);

        vm.roll(blockNumber);
        vm.coinbase(blockCoinbase);

        uint256 totalTickets = _contractUnderTest.totalTickets();
        uint256 pricePerTicket = _contractUnderTest.pricePerTicket();

        for (uint256 i = 0; i < totalTickets; i++) {
            vm.deal(address(this), pricePerTicket);
            _contractUnderTest.buyTickets{value: pricePerTicket}();
        }

        address seed1 = _contractUnderTest.contestants(uint(uint160(blockCoinbase)) % totalTickets).addr;
        address seed2 = _contractUnderTest.contestants(uint(uint160(address(this))) % totalTickets).addr;
        uint256 seed3 = block.difficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));

        uint256 expectedWinningNumber = uint(randHash) % totalTickets;
        address expectedWinner = _contractUnderTest.contestants(expectedWinningNumber).addr;

        _contractUnderTest.chooseWinner();

        address actualWinner = _contractUnderTest.contestants(expectedWinningNumber).addr;
        assertEq(actualWinner, expectedWinner, "Winner should be predictable given block state");
    }
}
