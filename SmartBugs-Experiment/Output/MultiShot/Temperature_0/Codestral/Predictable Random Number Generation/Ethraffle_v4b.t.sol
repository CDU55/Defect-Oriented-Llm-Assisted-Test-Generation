
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
        vm.assume(blockNumber < type(uint256).max);

        vm.roll(blockNumber);
        vm.coinbase(blockCoinbase);

        address seed1 = blockCoinbase;
        address seed2 = address(this);
        uint256 seed3 = block.difficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint(randHash) % 50;

        _contractUnderTest.buyTickets{value: 100 ether}();

        emit log_named_uint("Expected Winning Number", expectedWinningNumber);
    }
}
