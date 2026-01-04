
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= 1);
        vm.assume(blockNumber <= type(uint256).max - 1);

        address alice = address(0x1);
        address bob = address(0x2);
        vm.deal(alice, 2 ether);
        vm.deal(bob, 2 ether);

        vm.prank(alice);
        (bool successAlice, ) = address(_contractUnderTest).call{value: 1 ether}("");
        require(successAlice, "Alice deposit failed");

        vm.roll(blockNumber);
        bytes32 mockHash = bytes32(uint256(123456789));
        vm.mockBlockHash(blockNumber - 1, mockHash);

        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / 2;
        uint256 expectedIndex = (uint256(mockHash) / factor) % 2;

        uint256 preBalanceAlice = address(alice).balance;
        uint256 preBalanceBob = address(bob).balance;

        vm.prank(bob);
        (bool successBob, ) = address(_contractUnderTest).call{value: 1 ether}("");
        require(successBob, "Bob deposit failed");

        if (expectedIndex == 0) {
            assertGt(address(alice).balance, preBalanceAlice);
            assertEq(address(bob).balance, preBalanceBob - 1 ether);
        } else {
            assertEq(address(alice).balance, preBalanceAlice);
            assertGt(address(bob).balance, preBalanceBob - 1 ether);
        }
    }
}
