// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface INew {
   function registerPlayers(address _player, bytes calldata imageHash) external;
   function setPlayerScore(address _player, uint256 _score) external;
   function rewardPlayer (address _player, uint256 _tokenId, uint256 _amount) external;
   function getPlayers() external view returns (address[] memory);
   function getTopScores() external view returns (address[] memory, uint256[] memory);
}