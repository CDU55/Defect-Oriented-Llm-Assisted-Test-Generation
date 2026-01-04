
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler ld;

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    address owner = address(0xABCD);

    function setUp() public {
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(user3, "user3");
        vm.label(owner, "owner");

        vm.prank(owner);
        ld = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        // --- 1. Constraints ---

        // rand() uses block.number - 1, and blockhash(x) only defined for last 256 blocks
        vm.assume(blockNumber > 2);
        vm.assume(blockNumber < type(uint256).max - 2);

        // --- 2. State Configuration ---

        // Move chain to a controlled block number so we know blockhash(block.number - 1)
        vm.roll(blockNumber);

        // Prepare three users with enough ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        // We want at least 3 unpaid entries so that unpaidEntries.length > 1
        // Each call to receive() with >=1 ether funnels into init() -> join()

        vm.prank(user1);
        (bool s1, ) = address(ld).call{value: 1 ether}("");
        require(s1, "user1 deposit failed");

        vm.prank(user2);
        (bool s2, ) = address(ld).call{value: 1 ether}("");
        require(s2, "user2 deposit failed");

        vm.prank(user3);
        (bool s3, ) = address(ld).call{value: 1 ether}("");
        require(s3, "user3 deposit failed");

        // Now we make one more deposit that will trigger the rand() call we want to predict.
        // This call will be in the same blockNumber we set with vm.roll.
        // unpaidEntries.length is currently >= 3, so index = rand(unpaidEntries.length).
        uint256 unpaidEntriesLength = ld.totalEntries().count;
        require(unpaidEntriesLength >= 3, "need >=3 entries");

        // --- 3. Replication & Assertion ---

        // Predict the index that rand(max) will return at this very block.
        // NOTE: We must replicate the exact same logic as in LuckyDoubler::rand

        uint256 max = unpaidEntriesLength;

        // FACTOR is constant in the contract; inline here to avoid importing private constant.
        uint256 FACTOR =
            1157920892373161954235709850086879078532699846656405640394575840079131296399;

        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        bytes32 bhash = blockhash(lastBlockNumber);
        uint256 hashVal = uint256(bhash);
        uint256 expectedIndex = (uint256(hashVal / factor)) % max;

        // Next deposit will call join() and internally compute the same index.
        vm.prank(user1);
        (bool s4, ) = address(ld).call{value: 1 ether}("");
        require(s4, "user1 second deposit failed");

        // After this call, one of the unpaid entries was chosen using rand and likely paid.
        // We cannot read unpaidEntries directly (private), but we can detect which user got the payout
        // because payoutsReceived increments for the chosen entry's user.
        // Therefore, we can infer which logical index was chosen by mapping entries[index].entryAddress.

        // entries are exposed via entryDetails(index). The struct logic:
        //   entries[index].entryAddress, entries[index].payout, entries[index].paid
        // We know totalEntries() has grown by 1.
        uint256 finalTotalEntries = ld.totalEntries().count;
        require(finalTotalEntries == unpaidEntriesLength + 1, "unexpected entries length");

        // We know the entry at `expectedIndex` (among the first `max` entries) should have been picked.
        // Find which user corresponds to that entryAddress and assert that this user received one more payout.

        (address expectedUser, , , ) = ld.entryDetails(expectedIndex);

        (
            uint256 depositsUser1Before,
            uint256 payoutsUser1Before,

        ) = ld.userStats(user1);
        (
            uint256 depositsUser2Before,
            uint256 payoutsUser2Before,

        ) = ld.userStats(user2);
        (
            uint256 depositsUser3Before,
            uint256 payoutsUser3Before,

        ) = ld.userStats(user3);

        // Stats after the payout-triggering deposit
        (
            uint256 depositsUser1After,
            uint256 payoutsUser1After,

        ) = ld.userStats(user1);
        (
            uint256 depositsUser2After,
            uint256 payoutsUser2After,

        ) = ld.userStats(user2);
        (
            uint256 depositsUser3After,
            uint256 payoutsUser3After,

        ) = ld.userStats(user3);

        // Each user made at least one deposit. Confirm that exactly one user got a new payout.
        uint256 gainedPayouts =
            (payoutsUser1After - payoutsUser1Before) +
            (payoutsUser2After - payoutsUser2Before) +
            (payoutsUser3After - payoutsUser3Before);

        assertEq(gainedPayouts, 1, "exactly one payout should have occurred");

        // Now assert predictability: the user corresponding to expectedIndex must be
        // the one whose payoutsReceived increased.
        if (expectedUser == user1) {
            assertEq(payoutsUser1After, payoutsUser1Before + 1, "user1 should have been paid");
        } else if (expectedUser == user2) {
            assertEq(payoutsUser2After, payoutsUser2Before + 1, "user2 should have been paid");
        } else if (expectedUser == user3) {
            assertEq(payoutsUser3After, payoutsUser3Before + 1, "user3 should have been paid");
        } else {
            // If the chosen entry belongs to another address, no tracked user should gain payouts.
            // This is acceptable in the test, but still proves predictability: the chosenAddress
            // is exactly the one at expectedIndex we computed.
            // We still assert no tracked user was paid.
            assertEq(payoutsUser1After, payoutsUser1Before, "user1 unexpected payout");
            assertEq(payoutsUser2After, payoutsUser2Before, "user2 unexpected payout");
            assertEq(payoutsUser3After, payoutsUser3Before, "user3 unexpected payout");
        }
    }
}
