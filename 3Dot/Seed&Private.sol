// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// Importing OpenZeppelin's standard interfaces and utilities for ERC20 tokens and contract ownership management
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A smart contract for Vasting
/// @notice This contract allows the owner to create seeds for token holders and manage their claims
/// @dev Utilizes OpenZeppelin's contracts for ERC20 interactions and ownership management
/// @author 3 Dot Link Team
contract ThreeDot is Ownable {
    // Using the SafeERC20 library for safer ERC20 token interactions
    using SafeERC20 for IERC20;

    // Structure to store information about each round
    struct Round {
        address erc20;         // The ERC20 token address associated with the round
        uint totalHolding;     // Total amount of tokens held in the round
        uint usdAmount;        // The price associated with the round (not actively used in the contract)
        uint tokenPrice;       // tokenPrice of each round
        uint withdrawTime;     // The last time the holder made a withdrawal
        bool isActive;         // Boolean to indicate whether Holder is currently active
    }

    // State variables
    address public erc20;        // The address of the ERC20(3DOT) token used in this contract
    uint public seedValue;       // Value assigned to each seed round
    uint public privateValue;    // Value assigned to each private round
    uint public publicValue;     // Value assigned to each public round
    bool public isClaimActive;   // Boolean to indicate whether claims are currently active
    uint public claimEndDate;    // The end date for the claim period
    uint public claimStartDate;  // The start date for the claim period
    uint public TotalDays;       // Total number of days in the claim period

    // Mapping to store each holder's Seed information
    mapping (address => mapping(uint => Round)) public rounds; 

    /// @notice Constructor to set initial values for the contract
    /// @param initialOwner The address of the initial owner of the contract
    /// @param _ERC20 The ERC20 token address associated with the contract
    /// @param _seedValue The initial value assigned to each seed round
    /// @param _privateValue The initial value assigned to each private round
    /// @param _publicValue The initial value assigned to each public round
    constructor(address initialOwner, address _ERC20, uint _seedValue, uint _privateValue,uint _publicValue) Ownable(initialOwner) {
        erc20 = _ERC20;
        seedValue = _seedValue;
        privateValue = _privateValue;
        publicValue = _publicValue;
    }

    /// @notice Function to add a seed to a holder
    /// @dev Can only be called by the contract owner
    /// @param _Holder The address of the holder receiving the seed
    /// @param _amount The amount of tokens associated with the seed
    function addSeed(address _Holder, uint _amount) public onlyOwner {
        require(_Holder != address(0), "Put valid address!");
        require(_amount > 0, "Amount must be greater than zero!");
        uint tokenHolding = _amount / seedValue;
        IERC20(erc20).transferFrom(msg.sender, address(this), tokenHolding);
        rounds[_Holder][1] = Round(erc20, tokenHolding, _amount, seedValue, 0,true);
    }
    /// @notice Function to add a seed to a holder
    /// @dev Can only be called by the contract owner
    /// @param _Holder The address of the holder receiving the seed
    /// @param _amount The amount of tokens associated with the seed
    function addPrivate(address _Holder, uint _amount) public onlyOwner {
        require(_Holder != address(0), "Put valid address!");
        require(_amount > 0, "Amount must be greater than zero!");
        uint tokenHolding = _amount / seedValue;
        IERC20(erc20).transferFrom(msg.sender, address(this), tokenHolding);
        rounds[_Holder][2] = Round(erc20, tokenHolding, _amount, seedValue, 0,true);
    }
    /// @notice Function to add a seed to a holder
    /// @dev Can only be called by the contract owner
    /// @param _Holder The address of the holder receiving the seed
    /// @param _amount The amount of tokens associated with the seed
    function addPublic(address _Holder, uint _amount) public onlyOwner {
        require(_Holder != address(0), "Put valid address!");
        require(_amount > 0, "Amount must be greater than zero!");
        uint tokenHolding = _amount / seedValue;
        IERC20(erc20).transferFrom(msg.sender, address(this), tokenHolding);
        rounds[_Holder][3] = Round(erc20, tokenHolding, _amount, seedValue, 0,true);
    }
    
    /*
        ========== Vesting Rounds ==========
       
        There are three types of rounds in vesting
        1. Seed Round  
        2. Private Round
        3. Public Round   

    
    */

    /// @notice Function to get the seed information of a specific holder
    /// @param _Holder The address of the holder
    /// @return An array containing the seed , private and public information of the requested holder
    function getSeed(address _Holder) public view returns (Round[] memory,Round[] memory,Round[] memory) {
        Round[] memory seed = new Round[](1);
        Round[] memory _private = new Round[](1);
        Round[] memory _public = new Round[](1);
        seed[0] = rounds[_Holder][1];
        _private[0] = rounds[_Holder][2];
        _public[0] = rounds[_Holder][3];
        return (seed,_private,_public);
    }
    

    /// @notice Function to activate the claim feature
    /// @dev Can only be called by the contract owner
    /// @param startDate The start date for the claim period
    /// @param endDate The end date for the claim period
    function claimActive(uint startDate, uint endDate) public onlyOwner {
        require(startDate < endDate,"Please put valid time duration!");
        isClaimActive = true;
        claimEndDate = endDate;
        claimStartDate = startDate;
        TotalDays = (endDate - startDate) / 180;
    }

    /// @notice Function for holders to claim their tokens
    /// @dev Claims are based on the duration since the last claim
    /// @param _Holder The address of the holder making the claim
    /// @param roundTyp number of the round to their claim reward
    function ClaimToken(address _Holder,uint roundTyp) public {
        require(rounds[_Holder][roundTyp].isActive , "You are not Registered!");
        require(isClaimActive, "Claim is not Active so far!");
        uint withdrawSec = block.timestamp - (claimStartDate + rounds[_Holder][roundTyp].withdrawTime);
        uint exactWithdarawalTime = withdrawSec/180;
        rounds[_Holder][roundTyp].withdrawTime += exactWithdarawalTime * 180;
        uint DailyClaimTokens = rounds[_Holder][roundTyp].totalHolding / TotalDays;
        uint userClaimTokens = DailyClaimTokens * (withdrawSec / 180);
        require(userClaimTokens > 0, "Time is remaining for claim please wait!");
        uint contractBalance = IERC20(erc20).balanceOf(address(this));
        require(userClaimTokens <= contractBalance, "contract has Insufficient tokens!");
        IERC20(erc20).safeTransfer(msg.sender, userClaimTokens);
    }
    /// @notice Function for holders to check their tokens
    /// @param _Holder The address of the holder checking the claim
    /// @param roundTyp number of the round to check their claim reward
    function checkClaimReward(address _Holder,uint roundTyp) public  view returns(uint) {
        uint withdrawSec = block.timestamp - (claimStartDate + rounds[_Holder][roundTyp].withdrawTime);
        uint DailyClaimTokens = rounds[_Holder][roundTyp].totalHolding / TotalDays;
        uint userClaimTokens = DailyClaimTokens * (withdrawSec / 180);
        return userClaimTokens;
    }

    /// @notice Function to set a new seed value
    /// @dev Can only be called by the contract owner
    /// @param _seedValue The new seed value
    function setSeedPrice(uint _seedValue) public onlyOwner {
        seedValue = _seedValue;
    }
        /// @notice Function to set a new publicValue value
    /// @dev Can only be called by the contract owner
    /// @param _publicValue The new publicValue value
    function setPublicPrice(uint _publicValue) public onlyOwner {
        publicValue = _publicValue;
    }
    /// @notice Function to set a new privateValue value
    /// @dev Can only be called by the contract owner
    /// @param _privateValue The new privateValue value
    function setPrivatePrice(uint _privateValue) public onlyOwner {
        privateValue = _privateValue;
    }
}
