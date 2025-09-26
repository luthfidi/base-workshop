// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BasedBadge.sol";

contract BasedBadgeTest is Test {
    BasedBadge public badge;
    address public owner;
    address public student1;
    address public student2;
    address public minter;
    address public pauser;
    address public uriSetter;
    address public nonAuthorized;

    function setUp() public {
        owner = address(this);
        student1 = address(0x1);
        student2 = address(0x2);
        minter = address(0x3);
        pauser = address(0x4);
        uriSetter = address(0x5);
        nonAuthorized = address(0x6);

        badge = new BasedBadge();

        // Grant roles
        badge.grantRole(badge.MINTER_ROLE(), minter);
        badge.grantRole(badge.PAUSER_ROLE(), pauser);
        badge.grantRole(badge.URI_SETTER_ROLE(), uriSetter);
    }

    function testInitialSetup() public view {
        // Check role assignments
        assertTrue(badge.hasRole(badge.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(badge.hasRole(badge.MINTER_ROLE(), owner));
        assertTrue(badge.hasRole(badge.PAUSER_ROLE(), owner));
        assertTrue(badge.hasRole(badge.URI_SETTER_ROLE(), owner));
        assertTrue(badge.hasRole(badge.MINTER_ROLE(), minter));
        assertTrue(badge.hasRole(badge.PAUSER_ROLE(), pauser));
        assertTrue(badge.hasRole(badge.URI_SETTER_ROLE(), uriSetter));

        // Check constants
        assertEq(badge.CERTIFICATE_BASE(), 1000);
        assertEq(badge.EVENT_BADGE_BASE(), 2000);
        assertEq(badge.ACHIEVEMENT_BASE(), 3000);
        assertEq(badge.WORKSHOP_BASE(), 4000);
    }

    function testCreateBadgeType() public {
        string memory name = "Solidity Workshop";
        string memory category = "certificate";
        uint256 maxSupply = 100;
        bool transferable = false;
        string memory tokenURI = "https://example.com/cert/metadata";

        // Create certificate badge type
        vm.expectEmit(true, false, false, true);
        emit BasedBadge.TokenTypeCreated(1000, name, category);

        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType(name, category, maxSupply, transferable, tokenURI);

        assertEq(tokenId, 1000); // First certificate

        // Check token info
        (
            string memory storedName,
            string memory storedCategory,
            uint256 storedMaxSupply,
            bool storedTransferable,
            uint256 validUntil,
            address issuer
        ) = badge.tokenInfo(tokenId);

        assertEq(storedName, name);
        assertEq(storedCategory, category);
        assertEq(storedMaxSupply, maxSupply);
        assertEq(storedTransferable, transferable);
        assertEq(validUntil, 0);
        assertEq(issuer, minter);

        // Check URI
        assertEq(badge.uri(tokenId), tokenURI);
    }

    function testCreateDifferentBadgeCategories() public {
        // Create certificate (1000 base)
        vm.prank(minter);
        uint256 certId = badge.createBadgeType("Certificate", "certificate", 100, false, "cert_uri");
        assertEq(certId, 1000);

        // Create event badge (2000 base)
        vm.prank(minter);
        uint256 eventId = badge.createBadgeType("Event Badge", "event", 0, true, "event_uri");
        assertEq(eventId, 2000);

        // Create achievement (3000 base)
        vm.prank(minter);
        uint256 achievementId = badge.createBadgeType("Achievement", "achievement", 50, false, "achievement_uri");
        assertEq(achievementId, 3000);

        // Create workshop (4000 base - default category)
        vm.prank(minter);
        uint256 workshopId = badge.createBadgeType("Workshop", "workshop", 0, true, "workshop_uri");
        assertEq(workshopId, 4000);

        // Test unknown category defaults to workshop
        vm.prank(minter);
        uint256 unknownId = badge.createBadgeType("Unknown", "unknown", 0, true, "unknown_uri");
        assertEq(unknownId, 4001);
    }

    function testIssueBadge() public {
        // Create badge type first
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Workshop Badge", "event", 100, true, "uri");

        // Issue badge
        vm.expectEmit(true, true, false, false);
        emit BasedBadge.BadgeIssued(tokenId, student1);

        vm.prank(minter);
        badge.issueBadge(student1, tokenId);

        // Check balance and metadata
        assertEq(badge.balanceOf(student1, tokenId), 1);
        assertEq(badge.earnedAt(tokenId, student1), block.timestamp);

        // Check holder tokens mapping
        uint256[] memory holderTokens = badge.getTokensByHolder(student1);
        assertEq(holderTokens.length, 1);
        assertEq(holderTokens[0], tokenId);

        // Test total supply
        assertEq(badge.totalSupply(tokenId), 1);
    }

    function testIssueBadgeMaxSupplyLimit() public {
        // Create badge with max supply of 2
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Limited Badge", "achievement", 2, false, "uri");

        // Issue to first student
        vm.prank(minter);
        badge.issueBadge(student1, tokenId);

        // Issue to second student
        vm.prank(minter);
        badge.issueBadge(student2, tokenId);

        assertEq(badge.totalSupply(tokenId), 2);

        // Third issuance should fail
        vm.expectRevert("Max supply reached");
        vm.prank(minter);
        badge.issueBadge(student1, tokenId);
    }

    function testBatchIssueBadges() public {
        // Create badge type
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Event Badge", "event", 0, true, "uri");

        // Setup recipients
        address[] memory recipients = new address[](3);
        recipients[0] = student1;
        recipients[1] = student2;
        recipients[2] = address(0x7);

        // Batch issue
        vm.expectEmit(true, false, false, true);
        emit BasedBadge.BatchBadgesIssued(tokenId, 3);

        vm.prank(minter);
        badge.batchIssueBadges(recipients, tokenId, 2);

        // Check all recipients received badges
        for (uint i = 0; i < recipients.length; i++) {
            assertEq(badge.balanceOf(recipients[i], tokenId), 2);
            assertEq(badge.earnedAt(tokenId, recipients[i]), block.timestamp);
        }

        assertEq(badge.totalSupply(tokenId), 6); // 3 recipients * 2 badges each
    }

    function testGrantAchievement() public {
        string memory achievementName = "First Smart Contract";
        uint256 rarity = 10;

        // Grant achievement
        vm.expectEmit(false, true, false, true);
        emit BasedBadge.AchievementGranted(3000, student1, achievementName);

        vm.prank(minter);
        uint256 tokenId = badge.grantAchievement(student1, achievementName, rarity);

        assertEq(tokenId, 3000); // First achievement

        // Check token info
        (
            string memory name,
            string memory category,
            uint256 maxSupply,
            bool transferable,
            ,
            address issuer
        ) = badge.tokenInfo(tokenId);

        assertEq(name, achievementName);
        assertEq(category, "achievement");
        assertEq(maxSupply, rarity);
        assertFalse(transferable);
        assertEq(issuer, minter);

        // Check student received the achievement
        assertEq(badge.balanceOf(student1, tokenId), 1);
        assertEq(badge.earnedAt(tokenId, student1), block.timestamp);
    }

    function testCreateWorkshop() public {
        string memory seriesName = "DeFi Bootcamp";
        uint256 totalSessions = 5;

        vm.prank(minter);
        uint256[] memory sessionIds = badge.createWorkshop(seriesName, totalSessions);

        assertEq(sessionIds.length, totalSessions);

        // Check each session
        for (uint i = 0; i < totalSessions; i++) {
            assertEq(sessionIds[i], 4000 + i);

            (
                string memory name,
                string memory category,
                ,
                bool transferable,
                ,
                address issuer
            ) = badge.tokenInfo(sessionIds[i]);

            string memory expectedName = string(abi.encodePacked(seriesName, " Session ", vm.toString(i + 1)));
            assertEq(name, expectedName);
            assertEq(category, "workshop");
            assertTrue(transferable);
            assertEq(issuer, minter);
        }
    }

    function testSetURI() public {
        // Create badge first
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Test Badge", "event", 0, true, "old_uri");

        assertEq(badge.uri(tokenId), "old_uri");

        // Update URI
        string memory newURI = "https://new-metadata.com/token";
        vm.prank(uriSetter);
        badge.setURI(tokenId, newURI);

        assertEq(badge.uri(tokenId), newURI);

        // Test unauthorized URI setting
        vm.expectRevert();
        vm.prank(nonAuthorized);
        badge.setURI(tokenId, "unauthorized_uri");
    }

    function testVerifyBadge() public {
        // Create and issue badge
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Workshop Badge", "event", 0, true, "uri");

        vm.prank(minter);
        badge.issueBadge(student1, tokenId);

        // Verify badge
        (bool valid, uint256 earnedTimestamp) = badge.verifyBadge(student1, tokenId);
        assertTrue(valid);
        assertEq(earnedTimestamp, block.timestamp);

        // Check non-holder
        (bool validForNonHolder, uint256 earnedForNonHolder) = badge.verifyBadge(student2, tokenId);
        assertFalse(validForNonHolder);
        assertEq(earnedForNonHolder, 0);
    }

    function testPauseUnpause() public {
        // Create and issue badge first
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Test Badge", "event", 0, true, "uri");

        vm.prank(minter);
        badge.issueBadge(student1, tokenId);

        // Transfer should work normally
        vm.prank(student1);
        badge.safeTransferFrom(student1, student2, tokenId, 1, "");
        assertEq(badge.balanceOf(student2, tokenId), 1);

        // Pause the contract
        vm.prank(pauser);
        badge.pause();
        assertTrue(badge.paused());

        // Transfer should fail when paused
        vm.expectRevert();
        vm.prank(student2);
        badge.safeTransferFrom(student2, student1, tokenId, 1, "");

        // Minting should also fail when paused
        vm.expectRevert();
        vm.prank(minter);
        badge.issueBadge(student1, tokenId);

        // Unpause
        vm.prank(pauser);
        badge.unpause();
        assertFalse(badge.paused());

        // Transfer should work again
        vm.prank(student2);
        badge.safeTransferFrom(student2, student1, tokenId, 1, "");
        assertEq(badge.balanceOf(student1, tokenId), 1);
    }

    function testTransferRestrictions() public {
        // Create non-transferable badge (certificate)
        vm.prank(minter);
        uint256 nonTransferableId = badge.createBadgeType("Certificate", "certificate", 0, false, "uri");

        // Create transferable badge (event)
        vm.prank(minter);
        uint256 transferableId = badge.createBadgeType("Event Badge", "event", 0, true, "uri");

        // Issue both badges to student1
        vm.prank(minter);
        badge.issueBadge(student1, nonTransferableId);

        vm.prank(minter);
        badge.issueBadge(student1, transferableId);

        // Non-transferable badge transfer should fail
        vm.expectRevert("This token is non-transferable");
        vm.prank(student1);
        badge.safeTransferFrom(student1, student2, nonTransferableId, 1, "");

        // Transferable badge should work
        vm.prank(student1);
        badge.safeTransferFrom(student1, student2, transferableId, 1, "");
        assertEq(badge.balanceOf(student2, transferableId), 1);
    }

    function testUnauthorizedAccess() public {
        // Test unauthorized badge creation
        vm.expectRevert();
        vm.prank(nonAuthorized);
        badge.createBadgeType("Unauthorized", "event", 0, true, "uri");

        // Create badge first for other tests
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Test Badge", "event", 0, true, "uri");

        // Test unauthorized badge issuance
        vm.expectRevert();
        vm.prank(nonAuthorized);
        badge.issueBadge(student1, tokenId);

        // Test unauthorized achievement granting
        vm.expectRevert();
        vm.prank(nonAuthorized);
        badge.grantAchievement(student1, "Unauthorized Achievement", 10);

        // Test unauthorized workshop creation
        vm.expectRevert();
        vm.prank(nonAuthorized);
        badge.createWorkshop("Unauthorized Workshop", 3);

        // Test unauthorized pause
        vm.expectRevert();
        vm.prank(nonAuthorized);
        badge.pause();
    }

    function testSupportsInterface() public view {
        // Test ERC165 interface support
        assertTrue(badge.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(badge.supportsInterface(0xd9b67a26)); // ERC1155
        assertTrue(badge.supportsInterface(0x0e89341c)); // ERC1155MetadataURI
        assertTrue(badge.supportsInterface(0x7965db0b)); // AccessControl
    }

    function testEdgeCases() public {
        // Test issuing to non-existent token type
        vm.expectRevert("Token type does not exist");
        vm.prank(minter);
        badge.issueBadge(student1, 999);

        // Test batch issue with empty array
        address[] memory emptyRecipients = new address[](0);
        vm.prank(minter);
        uint256 tokenId = badge.createBadgeType("Test", "event", 0, true, "uri");

        vm.prank(minter);
        badge.batchIssueBadges(emptyRecipients, tokenId, 1);
        // Should not revert, just do nothing

        // Test creating badge with 0 max supply (unlimited)
        vm.prank(minter);
        uint256 unlimitedId = badge.createBadgeType("Unlimited", "event", 0, true, "uri");

        // Should be able to mint many
        for (uint i = 0; i < 10; i++) {
            vm.prank(minter);
            badge.issueBadge(student1, unlimitedId);
        }
        assertEq(badge.balanceOf(student1, unlimitedId), 10);
    }

    function testGetTokensByHolder() public {
        // Issue multiple different badges to same student
        vm.prank(minter);
        uint256 badge1 = badge.createBadgeType("Badge 1", "event", 0, true, "uri1");

        vm.prank(minter);
        uint256 badge2 = badge.createBadgeType("Badge 2", "achievement", 0, false, "uri2");

        vm.prank(minter);
        uint256 badge3 = badge.createBadgeType("Badge 3", "certificate", 0, false, "uri3");

        vm.prank(minter);
        badge.issueBadge(student1, badge1);

        vm.prank(minter);
        badge.issueBadge(student1, badge2);

        vm.prank(minter);
        badge.issueBadge(student1, badge3);

        uint256[] memory studentTokens = badge.getTokensByHolder(student1);
        assertEq(studentTokens.length, 3);

        // Check all badges are in the array (order might vary)
        bool found1 = false;
        bool found2 = false;
        bool found3 = false;

        for (uint i = 0; i < studentTokens.length; i++) {
            if (studentTokens[i] == badge1) found1 = true;
            if (studentTokens[i] == badge2) found2 = true;
            if (studentTokens[i] == badge3) found3 = true;
        }

        assertTrue(found1);
        assertTrue(found2);
        assertTrue(found3);
    }
}