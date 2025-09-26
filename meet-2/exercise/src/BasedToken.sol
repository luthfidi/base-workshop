// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title BasedToken
 * @dev ERC20 token with role-based access, pausing, and burnable features
 * Use cases:
 * - Fungible tokens (utility token, governance token, etc.)
 */
contract BasedToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    // TODO: Define role constants
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => bool) public blacklisted;   // ban certain users
    mapping(address => uint256) public lastClaim;  // track last reward claim

    constructor(uint256 initialSupply) ERC20("BasedToken", "BASED") {
        // TODO: Grant roles
        // 1. Grant DEFAULT_ADMIN_ROLE to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // 2. Grant MINTER_ROLE to deployer
        _grantRole(MINTER_ROLE, msg.sender);
        // 3. Grant PAUSER_ROLE to deployer
        _grantRole(PAUSER_ROLE, msg.sender);
        // 4. Mint initial supply to deployer
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    /**
     * @dev Mint new tokens
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        // TODO: Only MINTER_ROLE can call
        _mint(to, amount);
    }

    /**
     * @dev Pause all transfers
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        // TODO: Only PAUSER_ROLE can call
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        // TODO: Only PAUSER_ROLE can call
        _unpause();
    }
    
    /**
     * @dev Blacklist a user (only admin)
     */
    function setBlacklist(address user, bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: Only DEFAULT_ADMIN_ROLE can call
        // Update mapping
        blacklisted[user] = status;
    }

    /**
     * @dev Simple daily reward claim
     */
    function claimReward() public {
        // TODO:
        // 1. Check if 1 day passed since last claim
        require(block.timestamp >= lastClaim[msg.sender] + 1 days, "Cannot claim yet");
        require(!blacklisted[msg.sender], "User is blacklisted");
        // 2. Mint small reward to msg.sender
        _mint(msg.sender, 100 * 10**decimals());
        // 3. Update lastClaim[msg.sender]
        lastClaim[msg.sender] = block.timestamp;
    }

    /**
     * @dev Hook to block transfers when paused
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        // TODO: Add pause check
        require(!blacklisted[from] && !blacklisted[to], "Transfer blocked: blacklisted user");
        super._update(from, to, amount);
    }
}
