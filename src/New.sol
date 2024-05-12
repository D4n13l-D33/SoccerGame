// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Game {
    address owner;
    address NFTContractAddress;
    uint256 threshold;
    struct Player{
        address player;
        bytes imageHash;
        uint256 playerScore;
        bool isPlayer;
        bool rewarded;
    }
    enum gameDifficulty {Easy,Medium,Hard}
    mapping(address => Player) registeredPlayers;

    address[] players;

    constructor(address _lister, address ntfaddress, uint256 _threshold){
        NFTContractAddress = ntfaddress;
        threshold = _threshold;
        owner = _lister;
    }

    modifier onlyOwner(){
        require(tx.origin == owner, "You are not the owner of this listing");
        _;
    }

    function registerPlayers(address _player, bytes calldata imageHash) external {
        require(imageHash.length > 0, "Image Hash can't be empty");

        Player storage player = registeredPlayers[msg.sender];

        require(!player.isPlayer, "You are already registered");

        player.player = _player;
        player.imageHash = imageHash;
        player.isPlayer = true;

        players.push(msg.sender);
    }

    function setPlayerScore(address _player, uint256 _score) external{
        Player storage player = registeredPlayers[_player];
        require(player.isPlayer, "Player not registered");

        player.playerScore = _score;

    }

    function rewardPlayer (address _player, uint256 _tokenId, uint256 _amount) external onlyOwner{
        Player storage player = registeredPlayers[_player];
        require(!player.rewarded, "Already Rewarded");
        require(player.playerScore >= threshold, "Below threshold");
        player.rewarded = true;        
        IERC1155(NFTContractAddress).safeTransferFrom(msg.sender, _player, _tokenId, _amount, player.imageHash);

    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getTopScores() external view returns (address[] memory, uint256[] memory){
        uint256 totalplayers = players.length;
        address[] memory topPlayers = new address[](players.length);
        uint256[] memory topScores = new uint256[](players.length);

        for (uint256 i = 0; i < totalplayers; i++) {
            topPlayers[i] = address(0);
            topScores[i] = 0;
        }

        // Iterate through all players to find the top N players
        for (uint256 i = 0; i < totalplayers; i++) {
            address player = players[i];
            uint256 score = registeredPlayers[player].playerScore;

            // Check if the player's score is higher than the lowest score on the leaderboard
            for (uint256 j = 0; j < totalplayers; j++) {
                if (score > topScores[j]) {
                    // Shift the lower-ranked players down the leaderboard
                    for (uint256 k = totalplayers - 1; k > j; k--) {
                        topPlayers[k] = topPlayers[k - 1];
                        topScores[k] = topScores[k - 1];
                    }

                    // Update the leaderboard with the new top player
                    topPlayers[j] = player;
                    topScores[j] = score;
                    break;
                }
            }
        }

        // Return the top N players and their scores
        return (topPlayers, topScores); 
        }
}