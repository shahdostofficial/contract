// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title 3 Dot Link Project Main Utility Token
/// @author 3 Dot Link Team
/// @notice Contarct has fixed supply of tokens which is preminted
contract ThreeDotLink is ERC20, ERC20Pausable, Ownable {
    /// @notice Constructor of contract
    /// @param initialOwner Address of owner who can pause and unpause the contract
    constructor(address initialOwner)
        ERC20("Three Dot Link", "3DOT")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    /**
    * @dev Implementation of the ERC-20 token standard with the ability to pause and unpause
    * transfers and approvals.
    *
    * This function provides the owner with the ability to pause the token functionality
    * in case of emergencies, security vulnerabilities, or other unforeseen circumstances.
    *
    * The pausing mechanism allows the contract owner to temporarily halt all token transfers and
    * approvals, preventing potential exploits or vulnerabilities from being exploited.
    *
    * Reasons to Pause:
    * - Emergency situations
    * - Security vulnerabilities
    * - Upgrades and maintenance
    *
    * During the pause period:
    * - Token transfers and approvals are disabled
    * - Token balances remain unaffected
    * - Paused status is visible to all users
    *
    * The contract owner should exercise caution when using the pause feature and ensure that the
    * community is adequately informed of the reasons for pausing and any expected downtime.
    */
    function pause() public onlyOwner {
        _pause();
    }


    /**
     * @dev Unpause the token transfers and approvals.
     * Can only be called by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /** 
        Check Token Not Pause Before Transfer
    **/

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}