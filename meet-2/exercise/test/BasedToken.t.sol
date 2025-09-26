// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BasedToken.sol";

contract BasedTokenTest is Test {
    BasedToken public token;
    address public owner;
    address public user1;
    address public user2;
    address public minter;
    address public pauser;

    uint256 constant INITIAL_SUPPLY = 1000000; // 1M tokens

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        minter = address(0x3);
        pauser = address(0x4);

        token = new BasedToken(INITIAL_SUPPLY);

        // Grant roles to test accounts
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.PAUSER_ROLE(), pauser);
    }

    function testInitialSetup() public view {
        assertEq(token.name(), "BasedToken");
        assertEq(token.symbol(), "BASED");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 10**18);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY * 10**18);

        // Check roles
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(token.hasRole(token.MINTER_ROLE(), owner));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), owner));
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), pauser));
    }

    function testMinting() public {
        uint256 mintAmount = 1000 * 10**18;

        // Test successful minting by minter
        vm.prank(minter);
        token.mint(user1, mintAmount);
        assertEq(token.balanceOf(user1), mintAmount);

        // Test mint by owner
        token.mint(user2, mintAmount);
        assertEq(token.balanceOf(user2), mintAmount);

        // Test unauthorized minting fails
        vm.expectRevert();
        vm.prank(user1);
        token.mint(user2, mintAmount);
    }

    function testPauseUnpause() public {
        // Transfer should work normally
        token.transfer(user1, 1000 * 10**18);
        assertEq(token.balanceOf(user1), 1000 * 10**18);

        // Pause by pauser
        vm.prank(pauser);
        token.pause();
        assertTrue(token.paused());

        // Transfer should fail when paused
        vm.expectRevert();
        token.transfer(user2, 100 * 10**18);

        // Unpause by pauser
        vm.prank(pauser);
        token.unpause();
        assertFalse(token.paused());

        // Transfer should work again
        token.transfer(user2, 100 * 10**18);
        assertEq(token.balanceOf(user2), 100 * 10**18);

        // Test unauthorized pause fails
        vm.expectRevert();
        vm.prank(user1);
        token.pause();
    }

    function testBlacklist() public {
        // Blacklist user1
        token.setBlacklist(user1, true);
        assertTrue(token.blacklisted(user1));

        // Transfer to blacklisted user should fail
        vm.expectRevert("Transfer blocked: blacklisted user");
        token.transfer(user1, 1000 * 10**18);

        // Give user1 some tokens first (before blacklist)
        token.setBlacklist(user1, false);
        token.transfer(user1, 1000 * 10**18);
        assertEq(token.balanceOf(user1), 1000 * 10**18);

        // Now blacklist and try transfer from user1
        token.setBlacklist(user1, true);
        vm.expectRevert("Transfer blocked: blacklisted user");
        vm.prank(user1);
        token.transfer(user2, 100 * 10**18);

        // Remove from blacklist
        token.setBlacklist(user1, false);
        assertFalse(token.blacklisted(user1));

        // Transfer should work now
        vm.prank(user1);
        token.transfer(user2, 100 * 10**18);
        assertEq(token.balanceOf(user2), 100 * 10**18);

        // Test unauthorized blacklist fails
        vm.expectRevert();
        vm.prank(user1);
        token.setBlacklist(user2, true);
    }

    function testRewardClaim() public {
        uint256 rewardAmount = 100 * 10**18;

        // First claim should work
        vm.prank(user1);
        token.claimReward();
        assertEq(token.balanceOf(user1), rewardAmount);
        assertEq(token.lastClaim(user1), block.timestamp);

        // Second claim immediately should fail
        vm.expectRevert("Cannot claim yet");
        vm.prank(user1);
        token.claimReward();

        // Skip 1 day and try again
        vm.warp(block.timestamp + 1 days);
        vm.prank(user1);
        token.claimReward();
        assertEq(token.balanceOf(user1), rewardAmount * 2);

        // Blacklisted user can't claim
        token.setBlacklist(user2, true);
        vm.expectRevert("User is blacklisted");
        vm.prank(user2);
        token.claimReward();
    }

    function testBurn() public {
        uint256 burnAmount = 1000 * 10**18;

        // Transfer some tokens to user1
        token.transfer(user1, burnAmount);
        assertEq(token.balanceOf(user1), burnAmount);

        // User can burn their own tokens
        vm.prank(user1);
        token.burn(burnAmount);
        assertEq(token.balanceOf(user1), 0);

        // Check total supply decreased
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 10**18 - burnAmount);
    }

    function testBurnFrom() public {
        uint256 allowanceAmount = 1000 * 10**18;
        uint256 burnAmount = 500 * 10**18;

        // Transfer tokens to user1
        token.transfer(user1, allowanceAmount);

        // User1 approves user2 to burn their tokens
        vm.prank(user1);
        token.approve(user2, allowanceAmount);

        // User2 burns user1's tokens
        vm.prank(user2);
        token.burnFrom(user1, burnAmount);

        assertEq(token.balanceOf(user1), allowanceAmount - burnAmount);
        assertEq(token.allowance(user1, user2), allowanceAmount - burnAmount);
    }

    function testTransferWhenPausedShouldFail() public {
        token.transfer(user1, 1000 * 10**18);

        // Pause the contract
        vm.prank(pauser);
        token.pause();

        // All transfer operations should fail
        vm.expectRevert();
        vm.prank(user1);
        token.transfer(user2, 100 * 10**18);

        vm.expectRevert();
        token.transferFrom(user1, user2, 100 * 10**18);

        // Minting should also fail when paused
        vm.expectRevert();
        vm.prank(minter);
        token.mint(user2, 100 * 10**18);
    }

    function testSupportsInterface() public view {
        // Test ERC165 interface support
        assertTrue(token.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(token.supportsInterface(0x7965db0b)); // AccessControl
    }

    function testEdgeCases() public {
        // Test minting 0 tokens
        vm.prank(minter);
        token.mint(user1, 0);
        assertEq(token.balanceOf(user1), 0);

        // Test reward claim timing edge case
        vm.prank(user1);
        token.claimReward();

        // Exactly 1 day later should work
        vm.warp(block.timestamp + 1 days);
        vm.prank(user1);
        token.claimReward();
        assertEq(token.balanceOf(user1), 200 * 10**18);

        // 1 second less than 1 day should fail
        vm.warp(block.timestamp + 1 days - 1);
        vm.expectRevert("Cannot claim yet");
        vm.prank(user1);
        token.claimReward();
    }
}