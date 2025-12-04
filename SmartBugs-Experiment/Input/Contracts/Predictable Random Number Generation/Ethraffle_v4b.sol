pragma solidity 0.8.29;

contract Ethraffle_v4b {
    struct Contestant {
        address addr;
        uint raffleId;
    }

    event RaffleResult(
        uint raffleId,
        uint winningNumber,
        address winningAddress,
        address seed1,
        address seed2,
        uint seed3,
        bytes32 randHash
    );

    event TicketPurchase(
        uint raffleId,
        address contestant,
        uint number
    );

    event TicketRefund(
        uint raffleId,
        address contestant,
        uint number
    );

    // Constants
    uint public constant prize = 2.5 ether;
    uint public constant fee = 0.03 ether;
    uint public constant totalTickets = 50;
    uint public constant pricePerTicket = (prize + fee) / totalTickets; // Make sure this divides evenly
    address feeAddress;

    // Other internal variables
    bool public paused = false;
    uint public raffleId = 1;
    uint public blockNumber = block.number;
    uint nextTicket = 0;
    mapping (uint => Contestant) contestants;
    uint[] gaps;

    // Initialization
    constructor() {
        feeAddress = msg.sender;
    }

    // Call buyTickets() when receiving Ether without calldata
    receive() external payable {
        buyTickets();
    }

    function buyTickets() public payable {
        if (paused) {
            payable(msg.sender).transfer(msg.value);
            return;
        }

        uint moneySent = msg.value;

        while (moneySent >= pricePerTicket && nextTicket < totalTickets) {
            uint currTicket = 0;
            if (gaps.length > 0) {
                currTicket = gaps[gaps.length-1];
                gaps.pop();
            } else {
                currTicket = nextTicket++;
            }

            contestants[currTicket] = Contestant(msg.sender, raffleId);
            emit TicketPurchase(raffleId, msg.sender, currTicket);
            moneySent -= pricePerTicket;
        }

        // Choose winner if we sold all the tickets
        if (nextTicket == totalTickets) {
            chooseWinner();
        }

        // Send back leftover money
        if (moneySent > 0) {
            payable(msg.sender).transfer(moneySent);
        }
    }

    function chooseWinner() private {
        address seed1 = contestants[uint(uint160(address(block.coinbase))) % totalTickets].addr;
        address seed2 = contestants[uint(uint160(address(msg.sender))) % totalTickets].addr;
        uint seed3 = block.difficulty;
        bytes32 randHash = keccak256(abi.encodePacked(seed1, seed2, seed3));

        uint winningNumber = uint(randHash) % totalTickets;
        address winningAddress = contestants[winningNumber].addr;
        emit RaffleResult(raffleId, winningNumber, winningAddress, seed1, seed2, seed3, randHash);

        // Start next raffle
        raffleId++;
        nextTicket = 0;
        blockNumber = block.number;

        // gaps.length = 0 isn't necessary here,
        // because buyTickets() eventually clears
        // the gaps array in the loop itself.

        // Distribute prize and fee
        payable(winningAddress).transfer(prize);
        payable(feeAddress).transfer(fee);
    }

    // Get your money back before the raffle occurs
    function getRefund() public {
        uint refund = 0;
        for (uint i = 0; i < totalTickets; i++) {
            if (msg.sender == contestants[i].addr && raffleId == contestants[i].raffleId) {
                refund += pricePerTicket;
                contestants[i] = Contestant(address(0), 0);
                gaps.push(i);
                emit TicketRefund(raffleId, msg.sender, i);
            }
        }

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    // Refund everyone's money, start a new raffle, then pause it
    function endRaffle() public {
        if (msg.sender == feeAddress) {
            paused = true;

            for (uint i = 0; i < totalTickets; i++) {
                if (raffleId == contestants[i].raffleId) {
                    emit TicketRefund(raffleId, contestants[i].addr, i);
                    payable(contestants[i].addr).transfer(pricePerTicket);
                }
            }

            emit RaffleResult(raffleId, totalTickets, address(0), address(0), address(0), 0, 0);
            raffleId++;
            nextTicket = 0;
            blockNumber = block.number;
            delete gaps;
        }
    }

    function togglePause() public {
        if (msg.sender == feeAddress) {
            paused = !paused;
        }
    }

    function kill() public {
        if (msg.sender == feeAddress) {
            selfdestruct(payable(feeAddress));
        }
    }
}
