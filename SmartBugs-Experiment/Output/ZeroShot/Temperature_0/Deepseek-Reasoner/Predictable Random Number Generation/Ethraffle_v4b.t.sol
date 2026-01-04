
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public raffle;
    uint256 constant PRICE_PER_TICKET = 0.0506 ether;
    address constant ALICE = address(0x1234);
    address constant BOB = address(0x5678);

    function setUp() public {
        raffle = new Ethraffle_v4b();
        deal(ALICE, 100 ether);
        deal(BOB, 100 ether);
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, address msgSender, uint256 blockDifficulty) public {
        vm.assume(blockCoinbase != address(0));
        vm.assume(uint256(uint160(blockCoinbase)) % 50 < 50);
        vm.assume(uint256(uint160(msgSender)) % 50 < 50);
        vm.assume(blockDifficulty != 0);

        vm.coinbase(blockCoinbase);

        uint256 seed1Index = uint256(uint160(blockCoinbase)) % 50;
        uint256 seed2Index = uint256(uint160(address(this))) % 50;
        address expectedSeed1 = ALICE;
        address expectedSeed2 = address(this);

        vm.deal(ALICE, 100 ether);
        vm.startPrank(ALICE);
        for (uint256 i = 0; i < 49; i++) {
            raffle.buyTickets{value: PRICE_PER_TICKET}();
        }
        vm.stopPrank();

        vm.prevrandao(bytes32(blockDifficulty));

        bytes32 expectedRandHash = keccak256(abi.encodePacked(expectedSeed1, expectedSeed2, blockDifficulty));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % 50;

        raffle.buyTickets{value: PRICE_PER_TICKET}();

        (,, address winningAddress,,,,) = abi.decode(vm.getRecordedLogs()[0].data, (uint256, uint256, address, address, address, uint256, bytes32));
        
        address expectedWinner;
        if (expectedWinningNumber < 49) {
            expectedWinner = ALICE;
        } else {
            expectedWinner = address(this);
        }
        
        assertEq(winningAddress, expectedWinner);
    }
}
