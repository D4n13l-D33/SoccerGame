// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Game} from "./New.sol";
import {INew} from "./INew.sol";

// Interface for the external API


contract SoccerGame is Ownable, ReentrancyGuard {
    
    address public platformOwner;
    uint256 public transactionFeePercentage; // Fee percentage charged for transactions

    struct Listing {
    string name;
    uint256 tokenId;
    uint88 deadline;
    address lister;
    bool active;
    address game;
    }

    event ListingCreated(uint256 indexed listingId, Listing listing);
    event ListingExecuted(uint256 indexed listingId, Listing listing);
    event PlayerRegistered(address indexed player, bytes imageIPFSHash);
    event QuestionAsked(string question);
    event QuestionAsked(uint256 indexed listingId, string question);
    event AnswerSubmitted(uint256 indexed listingId, address player, string answer, bool correct);
    event ScoreUpdated(address indexed player, uint256 score);
    event LeaderboardUpdated(address[] players, uint256[] scores);
    event TransactionFeeCollected(address indexed from, uint256 amount);

    // Mapping to track 
    mapping(address => uint256) public playerScores;
    mapping(address => bool) public isPlayer;
    mapping(uint256 => Listing) public listings;
    uint256 public listingId;
    uint256 public totalListings;

    modifier onlyListingOwner(uint256 _listingId) {
        require(listings[_listingId].lister == msg.sender, "Not the listing owner");
        _;
    }

    // Constructor
    constructor() Ownable(msg.sender) {}

    // Event emitted when a player is registered

   
   function createListing(string memory name, uint256 tokenId, uint256 durationInSeconds, uint256 threshold, address nftaddress) external {
    
    // Validate input parameters
    require(durationInSeconds > 0, "Duration must be greater than zero");

    // Calculate the deadline
    uint88 deadline = uint88(block.timestamp) + uint88(durationInSeconds);

    // Create a new listing
    Listing storage listing = listings[listingId];
    
    listing.lister = msg.sender;
    listing.deadline = deadline;
    listing.tokenId = tokenId;
    listing.name = name;
    listing.active = true;
    Game game = new Game(msg.sender, nftaddress, threshold);
    listing.game = address(game);
    listingId++;
    totalListings++;

    // Emit the event after updating state variables
    emit ListingCreated(listingId - 1, listings[listingId - 1]);
}


function executeListing(uint256 _listingId) external payable nonReentrant {
        require(_listingId < listingId, "Listing does not exist");
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing is not active");
        require(block.timestamp < listing.deadline, "Listing deadline has passed");
        require(msg.sender != listing.lister, "Listing owner cannot execute");
        listing.active = false;
        totalListings--;

        emit ListingExecuted(_listingId, listing);
    }

function registerPlayers(uint256 _listingId, bytes memory imageHash) external {
        require(_listingId < listingId, "Listing does not exist");
        Listing storage listing = listings[_listingId];
        INew(listing.game).registerPlayers(msg.sender, imageHash);
        emit PlayerRegistered(msg.sender, imageHash);
}

function setPlayerScore (uint256 _listingId, address player, uint256 score) external {
        require(_listingId < listingId, "Listing does not exist");
        Listing storage listing = listings[_listingId];
        INew(listing.game).setPlayerScore(player, score);
}

function rewardPlayers(uint256 _listingId, address _player, uint256 _tokenId, uint256 _amount) external {
        require(_listingId < listingId, "Listing does not exist");
        Listing storage listing = listings[_listingId];
        INew(listing.game).rewardPlayer(_player, _tokenId, _amount);
}

function getPlayers(uint _listingId) external view returns(address[] memory players){
        require(_listingId < listingId, "Listing does not exist");
        Listing storage listing = listings[_listingId];
        players = INew(listing.game).getPlayers();
}

function getTopScores(uint _listingId) external view returns (address[] memory topscorers, uint256[] memory topscores){
         require(_listingId < listingId, "Listing does not exist");
        Listing storage listing = listings[_listingId];
        (topscorers, topscores) = INew(listing.game).getTopScores();
}

function getListing(uint256 _listingId) external view returns (Listing memory) {
    // Ensure the listing exists
    require(_listingId < listingId, "Listing does not exist");
    
    // Return the details of the specified listing
    return listings[_listingId];
}
// Function to set transaction fee percentage (only platform owner)
    function setTransactionFeePercentage(uint256 _transactionFeePercentage) external {
        require(msg.sender == platformOwner, "Only platform owner can set transaction fee percentage");
        transactionFeePercentage = _transactionFeePercentage;
    }

    // Function to calculate transaction fee amount
    function calculateTransactionFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * transactionFeePercentage) / 100;
    }

    // Function to process transaction with fee deduction
    function processTransaction(uint256 _amount) internal returns (uint256) {
        uint256 fee = calculateTransactionFee(_amount);
        uint256 amountAfterFee = _amount - fee;

        // Transfer fee to platform owner
        payable(platformOwner).transfer(fee);

        // Emit event for transaction fee collected
        emit TransactionFeeCollected(msg.sender, fee);

        return amountAfterFee;
    }

function mintNFT(address _to, uint256 _tokenId, string memory _tokenURI) external view onlyOwner {
    // Mint a new NFT
    // Validate input parameters
    require(_to != address(0), "Invalid recipient address");
    require(_tokenId > 0, "Token ID must be greater than zero");
    require(bytes(_tokenURI).length > 0, "Token URI must not be empty");
}
}