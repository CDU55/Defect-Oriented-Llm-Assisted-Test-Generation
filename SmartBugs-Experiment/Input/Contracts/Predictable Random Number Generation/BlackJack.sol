pragma solidity 0.8.29;

library Deck {
    // returns random number from 0 to 51
    function deal(address player, uint8 cardNumber) internal view returns (uint8) {
        uint b = block.number;
        uint timestamp = block.timestamp;
        return uint8(uint256(keccak256(abi.encodePacked(blockhash(b), player, cardNumber, timestamp))) % 52);
    }

    function valueOf(uint8 card, bool isBigAce) internal pure returns (uint8) {
        uint8 value = card / 4;
        if (value == 0 || value == 11 || value == 12) { // Face cards
            return 10;
        }
        if (value == 1 && isBigAce) { // Ace is worth 11
            return 11;
        }
        return value;
    }

    function isAce(uint8 card) internal pure returns (bool) {
        return card / 4 == 1;
    }

    function isTen(uint8 card) internal pure returns (bool) {
        return card / 4 == 10;
    }
}

contract BlackJack {
    using Deck for *;

    uint public minBet = 0.05 ether; // 0.05 eth
    uint public maxBet = 5 ether;

    uint8 constant BLACKJACK = 21;

    enum GameState { Ongoing, Player, Tie, House }

    struct Game {
        address player;
        uint bet;
        uint8[] houseCards;
        uint8[] playerCards;
        GameState state;
        uint8 cardsDealt;
    }

    mapping(address => Game) public games;

    modifier gameIsGoingOn() {
        require(games[msg.sender].player != address(0) && games[msg.sender].state == GameState.Ongoing, "game not ongoing");
        _;
    }

    event Deal(bool isUser, uint8 _card);
    event GameStatus(uint8 houseScore, uint8 houseScoreBig, uint8 playerScore, uint8 playerScoreBig);
    event Log(uint8 value);

    constructor() {}
    receive() external payable {}

    // starts a new game
    function deal() public payable {
        require(!(games[msg.sender].player != address(0) && games[msg.sender].state == GameState.Ongoing), "game is already going on");
        require(msg.value >= minBet && msg.value <= maxBet, "incorrect bet");

        uint8[] memory houseCards = new uint8[](1);
        uint8[] memory playerCards = new uint8[](2);

        playerCards[0] = Deck.deal(msg.sender, 0);
        emit Deal(true, playerCards[0]);
        houseCards[0] = Deck.deal(msg.sender, 1);
        emit Deal(false, houseCards[0]);
        playerCards[1] = Deck.deal(msg.sender, 2);
        emit Deal(true, playerCards[1]);

        games[msg.sender] = Game({
            player: msg.sender,
            bet: msg.value,
            houseCards: houseCards,
            playerCards: playerCards,
            state: GameState.Ongoing,
            cardsDealt: 3
        });

        checkGameResult(games[msg.sender], false);
    }

    // deals one more card to the player
    function hit() public gameIsGoingOn {
        uint8 nextCard = games[msg.sender].cardsDealt;
        games[msg.sender].playerCards.push(Deck.deal(msg.sender, nextCard));
        games[msg.sender].cardsDealt = nextCard + 1;
        emit Deal(true, games[msg.sender].playerCards[games[msg.sender].playerCards.length - 1]);
        checkGameResult(games[msg.sender], false);
    }

    // finishes the game
    function stand() public gameIsGoingOn {
        (uint8 houseScore, uint8 houseScoreBig) = calculateScore(games[msg.sender].houseCards);

        while (houseScoreBig < 17) {
            uint8 nextCard = games[msg.sender].cardsDealt;
            uint8 newCard = Deck.deal(msg.sender, nextCard);
            games[msg.sender].houseCards.push(newCard);
            games[msg.sender].cardsDealt = nextCard + 1;
            houseScoreBig += Deck.valueOf(newCard, true);
            emit Deal(false, newCard);
        }

        checkGameResult(games[msg.sender], true);
    }

    // determine result and pay out if necessary
    function checkGameResult(Game storage game, bool finishGame) private {
        (uint8 houseScore, uint8 houseScoreBig) = calculateScore(game.houseCards);
        (uint8 playerScore, uint8 playerScoreBig) = calculateScore(game.playerCards);

        emit GameStatus(houseScore, houseScoreBig, playerScore, playerScoreBig);

        if (houseScoreBig == BLACKJACK || houseScore == BLACKJACK) {
            if (playerScore == BLACKJACK || playerScoreBig == BLACKJACK) {
                // TIE
                payable(msg.sender).transfer(game.bet);
                games[msg.sender].state = GameState.Tie;
                return;
            } else {
                // HOUSE WON
                games[msg.sender].state = GameState.House;
                return;
            }
        } else {
            if (playerScore == BLACKJACK || playerScoreBig == BLACKJACK) {
                // PLAYER WON
                if (game.playerCards.length == 2 && (Deck.isTen(game.playerCards[0]) || Deck.isTen(game.playerCards[1]))) {
                    // Natural blackjack => return x2.5
                    payable(msg.sender).transfer((game.bet * 5) / 2);
                } else {
                    // Usual blackjack => return x2
                    payable(msg.sender).transfer(game.bet * 2);
                }
                games[msg.sender].state = GameState.Player;
                return;
            } else {
                if (playerScore > BLACKJACK) {
                    // BUST, HOUSE WON
                    emit Log(1);
                    games[msg.sender].state = GameState.House;
                    return;
                }

                if (!finishGame) {
                    return; // continue the game
                }

                uint8 playerShortage;
                uint8 houseShortage;

                if (playerScoreBig > BLACKJACK) {
                    if (playerScore > BLACKJACK) {
                        games[msg.sender].state = GameState.House;
                        return;
                    } else {
                        playerShortage = BLACKJACK - playerScore;
                    }
                } else {
                    playerShortage = BLACKJACK - playerScoreBig;
                }

                if (houseScoreBig > BLACKJACK) {
                    if (houseScore > BLACKJACK) {
                        payable(msg.sender).transfer(game.bet * 2);
                        games[msg.sender].state = GameState.Player;
                        return;
                    } else {
                        houseShortage = BLACKJACK - houseScore;
                    }
                } else {
                    houseShortage = BLACKJACK - houseScoreBig;
                }

                if (houseShortage == playerShortage) {
                    // TIE
                    payable(msg.sender).transfer(game.bet);
                    games[msg.sender].state = GameState.Tie;
                } else if (houseShortage > playerShortage) {
                    // PLAYER WON
                    payable(msg.sender).transfer(game.bet * 2);
                    games[msg.sender].state = GameState.Player;
                } else {
                    games[msg.sender].state = GameState.House;
                }
            }
        }
    }

    function calculateScore(uint8[] memory cards) private pure returns (uint8, uint8) {
        uint8 score = 0;
        uint8 scoreBig = 0;
        bool bigAceUsed = false;
        for (uint i = 0; i < cards.length; ++i) {
            uint8 card = cards[i];
            if (Deck.isAce(card) && !bigAceUsed) {
                scoreBig += Deck.valueOf(card, true);
                bigAceUsed = true;
            } else {
                scoreBig += Deck.valueOf(card, false);
            }
            score += Deck.valueOf(card, false);
        }
        return (score, scoreBig);
    }

    function getPlayerCard(uint8 id) public view gameIsGoingOn returns (uint8) {
        require(id < games[msg.sender].playerCards.length, "index OOB");
        return games[msg.sender].playerCards[id];
    }

    function getHouseCard(uint8 id) public view gameIsGoingOn returns (uint8) {
        require(id < games[msg.sender].houseCards.length, "index OOB");
        return games[msg.sender].houseCards[id];
    }

    function getPlayerCardsNumber() public view gameIsGoingOn returns (uint) {
        return games[msg.sender].playerCards.length;
    }

    function getHouseCardsNumber() public view gameIsGoingOn returns (uint) {
        return games[msg.sender].houseCards.length;
    }

    function getGameState() public view returns (uint8) {
        require(games[msg.sender].player != address(0), "game doesn't exist");
        Game storage game = games[msg.sender];
        if (game.state == GameState.Player) return 1;
        if (game.state == GameState.House) return 2;
        if (game.state == GameState.Tie) return 3;
        return 0;
    }
}
