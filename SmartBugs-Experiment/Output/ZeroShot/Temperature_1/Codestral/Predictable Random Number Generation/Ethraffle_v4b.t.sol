
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {

    Ethraffle_v4b public contractUnderTest;

    function setUp() public {
        contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(uint blockNumber, uint blockDifficulty, address blockCoinbase) public {
        // --- 1. Constraints ---
        blockNumber = bound(blockNumber, 1, 1000000000);
        blockDifficulty = bound(blockDifficulty, 1, 1000000000000000000000000000000000000000);
        blockCoinbase = vm.addr(blockCoinbase);

        // --- 2. State Configuration ---
        vm.deal(address(contractUnderTest), 50 * contractUnderTest.pricePerTicket());

        // --- 3. Manipulate Block Environment ---
        vm.roll(blockNumber);
        vm.coinbase(blockCoinbase);

        // --- 4. Replication & Assertion ---
        // Calculate expected winning number
        address seed1 = vm.addr(uint160(address(blockCoinbase)) % contractUnderTest.totalTickets());
        address seed2 = vm.addr(uint160(address(this)) % contractUnderTest.totalTickets());
        uint seed3 = blockDifficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint expectedWinningNumber = uint(randHash) % contractUnderTest.totalTickets();

        // Execute
        contractUnderTest.buyTickets{value: 50 * contractUnderTest.pricePerTicket()}();

        // Assert predictability
        uint actualWinningNumber = contractUnderTest.raffleId() - 1;
        assertEq(actualWinningNumber, expectedWinningNumber, "Random number is predictable");
    }
}
