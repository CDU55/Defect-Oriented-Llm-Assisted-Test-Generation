pragma solidity 0.8.29;
  
 contract Lottery {
     event GetBet(uint betAmount, uint blockNumber, bool won);

     struct Bet {
         uint betAmount;
         uint blockNumber;
         bool won;
     }

     address private organizer;
     Bet[] private bets;

     // Create a new lottery with numOfBets supported bets.
     constructor() {
         organizer = msg.sender;
     }

     // Fallback function reverts
     fallback() external {
         revert();
     }

    // Make a bet
    function makeBet() public payable {
         // Won if block number is even
         bool won = (block.number % 2) == 0;

         // Record the bet with an event
         bets.push(Bet(msg.value, block.number, won));

         // Payout if the user won, otherwise take their money
         if(won) {
             // send winnings back to sender (revert on failure)
             payable(msg.sender).transfer(msg.value);
         }
     }

    // Get all bets that have been made
    function getBets() public {
         require(msg.sender == organizer, "not organizer");

        for (uint i = 0; i < bets.length; i++) {
            emit GetBet(bets[i].betAmount, bets[i].blockNumber, bets[i].won);
        }
     }

     function destroy() public {
         require(msg.sender == organizer, "not organizer");

         selfdestruct(payable(organizer));
     }
 }
