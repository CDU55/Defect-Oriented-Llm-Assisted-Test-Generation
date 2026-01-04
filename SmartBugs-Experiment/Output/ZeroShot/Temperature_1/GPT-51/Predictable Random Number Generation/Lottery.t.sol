
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery lottery;
    address attacker = address(0xBEEF);

    receive() external payable {}

    function setUp() public {
        lottery = new Lottery();
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > block.number);
        vm.assume(blockNumber < type(uint64).max);

        vm.deal(address(this), 100 ether);
        vm.roll(blockNumber);

        bool expectedWon = (blockNumber % 2) == 0;

        vm.prank(attacker);
        lottery.makeBet{value: 1 ether}();

        vm.prank(address(this));
        vm.expectRevert();
        lottery.getBets();

        vm.prank(address(lottery));
        emitDummyGetBetEvents();

        BetView[] memory bets = decodeBetsFromLogs();

        assertEq(bets.length, 1);
        assertEq(bets[0].blockNumber, blockNumber);
        assertEq(bets[0].won, expectedWon);
    }

    struct BetView {
        uint256 betAmount;
        uint256 blockNumber;
        bool won;
    }

    event DummyGetBet(uint256 betAmount, uint256 blockNumber, bool won);

    function emitDummyGetBetEvents() public {
        // This is a helper used only to get the event signature
        emit DummyGetBet(0, 0, false);
    }

    function decodeBetsFromLogs() internal returns (BetView[] memory) {
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 count;
        bytes32 dummySig = keccak256("DummyGetBet(uint256,uint256,bool)");

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == dummySig) {
                count++;
            }
        }

        BetView[] memory bets = new BetView[](count);
        uint256 idx;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == dummySig) {
                (uint256 betAmount, uint256 blockNumber, bool won) =
                    abi.decode(entries[i].data, (uint256, uint256, bool));
                bets[idx] = BetView(betAmount, blockNumber, won);
                idx++;
            }
        }
        return bets;
    }
}
