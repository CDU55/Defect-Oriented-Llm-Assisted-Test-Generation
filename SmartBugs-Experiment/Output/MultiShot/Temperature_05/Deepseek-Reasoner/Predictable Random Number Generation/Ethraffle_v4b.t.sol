
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public _contractUnderTest;
    
    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(address blockCoinbase, uint256 blockPrevrandao) public {
        vm.assume(blockCoinbase != address(0));
        vm.assume(uint160(blockCoinbase) <= type(uint160).max);
        vm.assume(blockPrevrandao <= type(uint256).max);
        
        vm.deal(address(this), 100 ether);
        
        vm.coinbase(blockCoinbase);
        vm.prevrandao(bytes32(blockPrevrandao));
        
        uint256 totalTickets = 50;
        address seed1 = address(uint160(uint256(keccak256(abi.encodePacked(blockCoinbase)))) % totalTickets);
        address seed2 = address(uint160(uint256(keccak256(abi.encodePacked(address(this))))) % totalTickets);
        uint256 seed3 = blockPrevrandao;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(randHash) % totalTickets;
        
        for(uint256 i = 0; i < totalTickets; i++) {
            _contractUnderTest.buyTickets{value: _contractUnderTest.pricePerTicket()}();
        }
        
        assertEq(
            uint256(keccak256(abi.encodePacked(blockCoinbase, address(this), blockPrevrandao))) % totalTickets,
            expectedWinningNumber,
            "Randomness should be predictable given block state"
        );
    }
}
