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
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public lastClaim;

    constructor(uint256 initialSupply) ERC20("BasedToken", "BASED") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBlacklist(address user, bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklisted[user] = status;
    }

    function claimReward() public {
        require(block.timestamp >= lastClaim[msg.sender] + 1 days, "Cannot claim yet");
        require(!blacklisted[msg.sender], "User is blacklisted");
        _mint(msg.sender, 100 * 10**decimals());
        lastClaim[msg.sender] = block.timestamp;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(!blacklisted[from] && !blacklisted[to], "Transfer blocked: blacklisted user");
        super._update(from, to, amount);
    }
}