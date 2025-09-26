// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BasedCertificate.sol";

contract BasedCertificateTest is Test {
    BasedCertificate public certificate;
    address public owner;
    address public student1;
    address public student2;
    address public nonOwner;

    function setUp() public {
        owner = address(this);
        student1 = address(0x1);
        student2 = address(0x2);
        nonOwner = address(0x3);

        certificate = new BasedCertificate();
    }

    function testInitialSetup() public view {
        assertEq(certificate.name(), "Based Certificate");
        assertEq(certificate.symbol(), "BCERT");
        assertEq(certificate.owner(), owner);
    }

    function testIssueCertificate() public {
        string memory recipientName = "John Doe";
        string memory course = "Solidity Basics";
        string memory issuer = "Base Indonesia";
        string memory uri = "https://example.com/cert/1";

        // Issue certificate
        certificate.issueCertificate(student1, recipientName, course, issuer, uri);

        // Check ownership
        assertEq(certificate.ownerOf(1), student1);
        assertEq(certificate.balanceOf(student1), 1);

        // Check certificate data
        (
            string memory storedName,
            string memory storedCourse,
            string memory storedIssuer,
            uint256 issuedDate,
            bool valid
        ) = certificate.certificates(1);

        assertEq(storedName, recipientName);
        assertEq(storedCourse, course);
        assertEq(storedIssuer, issuer);
        assertEq(issuedDate, block.timestamp);
        assertTrue(valid);

        // Check URI
        assertEq(certificate.tokenURI(1), uri);

        // Check owner certificates mapping
        uint256[] memory ownerCerts = certificate.getCertificatesByOwner(student1);
        assertEq(ownerCerts.length, 1);
        assertEq(ownerCerts[0], 1);

        // Check event emission
        vm.expectEmit(true, true, false, true);
        emit BasedCertificate.CertificateIssued(2, student2, course, issuer);
        certificate.issueCertificate(student2, "Jane Doe", course, issuer, uri);
    }

    function testDuplicateCertificatePrevention() public {
        string memory recipientName = "John Doe";
        string memory course = "Solidity Basics";
        string memory issuer = "Base Indonesia";
        string memory uri = "https://example.com/cert/1";

        // Issue first certificate
        certificate.issueCertificate(student1, recipientName, course, issuer, uri);

        // Try to issue duplicate certificate - should fail
        vm.expectRevert("Certificate already exists");
        certificate.issueCertificate(student1, recipientName, course, issuer, uri);

        // Different recipient should work
        certificate.issueCertificate(student2, recipientName, course, issuer, uri);
        assertEq(certificate.balanceOf(student2), 1);
    }

    function testRevokeCertificate() public {
        // Issue certificate first
        certificate.issueCertificate(student1, "John Doe", "Solidity Basics", "Base Indonesia", "uri");

        // Check certificate is valid
        (, , , , bool valid) = certificate.certificates(1);
        assertTrue(valid);

        // Revoke certificate
        vm.expectEmit(true, false, false, false);
        emit BasedCertificate.CertificateRevoked(1);
        certificate.revokeCertificate(1);

        // Check certificate is now invalid
        (, , , , bool validAfterRevoke) = certificate.certificates(1);
        assertFalse(validAfterRevoke);

        // Try to revoke non-existent certificate
        vm.expectRevert("Token doesn't exist");
        certificate.revokeCertificate(999);
    }

    function testUpdateCertificate() public {
        string memory originalCourse = "Solidity Basics";
        string memory newCourse = "Advanced Solidity";

        // Issue certificate first
        certificate.issueCertificate(student1, "John Doe", originalCourse, "Base Indonesia", "uri");

        // Update course
        vm.expectEmit(true, false, false, true);
        emit BasedCertificate.CertificateUpdated(1, newCourse);
        certificate.updateCertificate(1, newCourse);

        // Check updated data
        (, string memory storedCourse, , ,) = certificate.certificates(1);
        assertEq(storedCourse, newCourse);

        // Try to update non-existent certificate
        vm.expectRevert("Token doesn't exist");
        certificate.updateCertificate(999, "Some Course");
    }

    function testBurnCertificate() public {
        // Issue certificate
        certificate.issueCertificate(student1, "John Doe", "Solidity Basics", "Base Indonesia", "uri");
        assertEq(certificate.balanceOf(student1), 1);

        // Check owner certificates before burn
        uint256[] memory certsBeforeBurn = certificate.getCertificatesByOwner(student1);
        assertEq(certsBeforeBurn.length, 1);

        // Burn certificate
        certificate.burnCertificate(1);

        // Check certificate no longer exists
        vm.expectRevert();
        certificate.ownerOf(1);

        assertEq(certificate.balanceOf(student1), 0);

        // Check owner certificates mapping is cleaned up
        uint256[] memory certsAfterBurn = certificate.getCertificatesByOwner(student1);
        assertEq(certsAfterBurn.length, 0);

        // Try to burn non-existent certificate
        vm.expectRevert("BCERT: token does not exist");
        certificate.burnCertificate(999);
    }

    function testSoulboundTransfer() public {
        // Issue certificate
        certificate.issueCertificate(student1, "John Doe", "Solidity Basics", "Base Indonesia", "uri");

        // Try to transfer - should fail (non-transferable/soulbound)
        vm.expectRevert("Certificates are non-transferable");
        vm.prank(student1);
        certificate.transferFrom(student1, student2, 1);

        // Try safe transfer - should also fail
        vm.expectRevert("Certificates are non-transferable");
        vm.prank(student1);
        certificate.safeTransferFrom(student1, student2, 1);

        // Approval should work but transfer still fails
        vm.prank(student1);
        certificate.approve(student2, 1);
        assertEq(certificate.getApproved(1), student2);

        vm.expectRevert("Certificates are non-transferable");
        vm.prank(student2);
        certificate.transferFrom(student1, student2, 1);
    }

    function testOnlyOwnerModifiers() public {
        // Try to issue certificate as non-owner
        vm.expectRevert();
        vm.prank(nonOwner);
        certificate.issueCertificate(student1, "John Doe", "Course", "Issuer", "uri");

        // Issue certificate as owner first
        certificate.issueCertificate(student1, "John Doe", "Course", "Issuer", "uri");

        // Try to revoke as non-owner
        vm.expectRevert();
        vm.prank(nonOwner);
        certificate.revokeCertificate(1);

        // Try to update as non-owner
        vm.expectRevert();
        vm.prank(nonOwner);
        certificate.updateCertificate(1, "New Course");

        // Try to burn as non-owner
        vm.expectRevert();
        vm.prank(nonOwner);
        certificate.burnCertificate(1);
    }

    function testMultipleCertificatesPerOwner() public {
        // Issue multiple certificates to same student
        certificate.issueCertificate(student1, "John Doe", "Course 1", "Issuer", "uri1");
        certificate.issueCertificate(student1, "John Doe", "Course 2", "Issuer", "uri2");
        certificate.issueCertificate(student1, "John Doe", "Course 3", "Issuer", "uri3");

        assertEq(certificate.balanceOf(student1), 3);

        // Check all certificates are tracked
        uint256[] memory certs = certificate.getCertificatesByOwner(student1);
        assertEq(certs.length, 3);
        assertEq(certs[0], 1);
        assertEq(certs[1], 2);
        assertEq(certs[2], 3);

        // Burn middle certificate
        certificate.burnCertificate(2);

        // Check remaining certificates
        uint256[] memory remainingCerts = certificate.getCertificatesByOwner(student1);
        assertEq(remainingCerts.length, 2);
        // Note: array order might change after removal, so check both exist
        assertTrue(remainingCerts[0] == 1 || remainingCerts[0] == 3);
        assertTrue(remainingCerts[1] == 1 || remainingCerts[1] == 3);
        assertTrue(remainingCerts[0] != remainingCerts[1]);
    }

    function testSupportsInterface() public view {
        // Test ERC165 interface support
        assertTrue(certificate.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(certificate.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(certificate.supportsInterface(0x5b5e139f)); // ERC721Metadata
    }

    function testTokenURIStorage() public {
        string memory uri1 = "https://example.com/cert/1";
        string memory uri2 = "https://example.com/cert/2";

        // Issue certificates with different URIs
        certificate.issueCertificate(student1, "John Doe", "Course 1", "Issuer", uri1);
        certificate.issueCertificate(student2, "Jane Doe", "Course 2", "Issuer", uri2);

        assertEq(certificate.tokenURI(1), uri1);
        assertEq(certificate.tokenURI(2), uri2);

        // Test non-existent token URI
        vm.expectRevert();
        certificate.tokenURI(999);
    }

    function testCertificateHashMapping() public {
        // Issue certificate
        certificate.issueCertificate(student1, "John Doe", "Course", "Issuer", "uri");

        // Check hash mapping is set
        string memory certHash = string(abi.encodePacked(student1, "John Doe", "Course", "Issuer"));
        assertEq(certificate.certHashToTokenId(certHash), 1);

        // Different parameters should create different hash
        certificate.issueCertificate(student2, "John Doe", "Course", "Issuer", "uri");
        string memory differentHash = string(abi.encodePacked(student2, "John Doe", "Course", "Issuer"));
        assertEq(certificate.certHashToTokenId(differentHash), 2);
    }
}