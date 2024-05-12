// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract QuestionAPIContract{

    mapping(uint256 => string) public correctAnswers;

    function setCorrectAnswer(uint256 _listingId, string memory _correctAnswer) external onlyOwner {
        correctAnswers[_listingId] = _correctAnswer;
    }

    function getCorrectAnswer(uint256 _listingId) external view returns (string memory) {
        return correctAnswers[_listingId];
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.24;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFT is Ownable {
// Address of the ERC721 token contract
address public nftContractAddress;

// Event to emit when a player receives a reward
event RewardReceived(address indexed player, uint256 tokenId);

// Function to set the address of the ERC721 token contract
function setNFTContractAddress(address _nftContractAddress) external onlyOwner {
    nftContractAddress = _nftContractAddress;
}

// Function to reward players with NFTs based on their score
function rewardPlayers(address[] memory _players, uint256[] memory _scores, uint256 _threshold, uint256 _tokenId) external onlyOwner {
    require(_players.length == _scores.length, "Arrays length mismatch");
    require(_players.length > 0, "No players to reward");

    // Iterate through the players and their scores
    for (uint256 i = 0; i < _players.length; i++) {
        if (_scores[i] >= _threshold) {
            // Transfer NFT to the player if their score meets the threshold
            IERC721(nftContractAddress).transferFrom(address(this), _players[i], _tokenId);
            emit RewardReceived(_players[i], _tokenId);
        }
    }
}
}