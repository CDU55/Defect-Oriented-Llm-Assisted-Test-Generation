// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract QuestGame {
    
    struct Player {
        uint256 experience;
        uint256 lastAttemptTime;
        uint256 wins;
    }

    mapping(address => Player) public players;
    uint256 public constant ENTRY_FEE = 0.1 ether;
    uint256 public constant REWARD = 0.2 ether;
    uint256 public constant COOLDOWN = 1 hours;

    event QuestAttempted(address indexed player, bool success, uint256 generatedNumber);

    constructor() payable {}

    receive() external payable {}

    function attemptQuest(uint256 userGuess) external payable {
        require(msg.value == ENTRY_FEE, "Incorrect entry fee");
        require(address(this).balance >= REWARD, "Contract out of funds");
        
        Player storage p = players[msg.sender];
        require(block.timestamp >= p.lastAttemptTime + COOLDOWN, "Cooldown active");

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.number, 
                    msg.sender 
                )
            )
        );

        uint256 generatedNumber = seed % 100;

        p.lastAttemptTime = block.timestamp;

        if (userGuess == generatedNumber) {
            p.experience += 100;
            p.wins++;
            (bool sent, ) = msg.sender.call{value: REWARD}("");
            require(sent, "Failed to send reward");
            emit QuestAttempted(msg.sender, true, generatedNumber);
        } else {
            emit QuestAttempted(msg.sender, false, generatedNumber);
        }
    }

    function getPlayerStats(address _player) external view returns (uint256 exp, uint256 wins) {
        return (players[_player].experience, players[_player].wins);
    }
}