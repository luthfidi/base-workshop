// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/BasedToken.sol";
import "../src/BasedCertificate.sol";
import "../src/BasedBadge.sol";

/**
 * @title Deploy Script for Based Workshop Contracts
 * @dev Deploys BasedToken (ERC20), BasedCertificate (ERC721), and BasedBadge (ERC1155)
 *
 * Usage:
 * forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
 */
contract DeployScript is Script {
    // Deployment parameters
    uint256 constant INITIAL_TOKEN_SUPPLY = 1000000; // 1M tokens

    // Deployed contract addresses (will be set after deployment)
    BasedToken public basedToken;
    BasedCertificate public basedCertificate;
    BasedBadge public basedBadge;

    function run() external {
        // Get deployer address from private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Based Workshop Contract Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);
        console.log("");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BasedToken (ERC20)
        console.log("Deploying BasedToken...");
        basedToken = new BasedToken(INITIAL_TOKEN_SUPPLY);
        console.log("BasedToken deployed at:", address(basedToken));
        console.log("Initial supply:", INITIAL_TOKEN_SUPPLY, "tokens");
        console.log("");

        // Deploy BasedCertificate (ERC721)
        console.log("Deploying BasedCertificate...");
        basedCertificate = new BasedCertificate();
        console.log("BasedCertificate deployed at:", address(basedCertificate));
        console.log("");

        // Deploy BasedBadge (ERC1155)
        console.log("Deploying BasedBadge...");
        basedBadge = new BasedBadge();
        console.log("BasedBadge deployed at:", address(basedBadge));
        console.log("");

        // Stop broadcasting
        vm.stopBroadcast();

        // Log final deployment summary
        console.log("=== Deployment Summary ===");
        console.log("BasedToken (ERC20):", address(basedToken));
        console.log("BasedCertificate (ERC721):", address(basedCertificate));
        console.log("BasedBadge (ERC1155):", address(basedBadge));
        console.log("");
        console.log("Deployer owns all contracts and has all admin roles.");
        console.log("Remember to verify contracts on Basescan!");
        console.log("");

        // Optional: Setup some initial data for testing
        setupInitialData(deployerPrivateKey);
    }

    /**
     * @dev Sets up some initial data for testing purposes
     * This function demonstrates how to interact with deployed contracts
     */
    function setupInitialData(uint256 deployerPrivateKey) internal {
        console.log("=== Setting up initial test data ===");

        vm.startBroadcast(deployerPrivateKey);

        // Create some initial badge types in BasedBadge
        try basedBadge.createBadgeType(
            "Base Workshop Certificate",
            "certificate",
            100, // Max supply
            false, // Non-transferable
            "https://base-workshop.com/api/certificate/metadata"
        ) returns (uint256 certBadgeId) {
            console.log("Created certificate badge type with ID:", certBadgeId);
        } catch {
            console.log("Failed to create certificate badge type");
        }

        try basedBadge.createBadgeType(
            "Workshop Participation Badge",
            "event",
            0, // Unlimited supply
            true, // Transferable
            "https://base-workshop.com/api/participation/metadata"
        ) returns (uint256 eventBadgeId) {
            console.log("Created event badge type with ID:", eventBadgeId);
        } catch {
            console.log("Failed to create event badge type");
        }

        try basedBadge.createWorkshop("Solidity Fundamentals", 5) returns (uint256[] memory sessionIds) {
            console.log("Created workshop series with", sessionIds.length, "sessions");
            console.log("First session ID:", sessionIds[0]);
            console.log("Last session ID:", sessionIds[sessionIds.length - 1]);
        } catch {
            console.log("Failed to create workshop series");
        }

        vm.stopBroadcast();
        console.log("Initial test data setup completed!");
        console.log("");
    }

    /**
     * @dev Helper function to verify all contracts after deployment
     * Run this separately after deployment if needed
     */
    function verifyContracts() external view {
        console.log("=== Contract Verification Info ===");
        console.log("Run these commands to verify on Basescan:");
        console.log("");

        console.log("forge verify-contract \\");
        console.log("  --chain-id 84532 \\");
        console.log("  --compiler-version v0.8.26 \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(uint256)\" 1000000) \\");
        console.log("  --etherscan-api-key $BASESCAN_API_KEY \\");
        console.log("  ", address(basedToken), " \\");
        console.log("  src/BasedToken.sol:BasedToken");
        console.log("");

        console.log("forge verify-contract \\");
        console.log("  --chain-id 84532 \\");
        console.log("  --compiler-version v0.8.26 \\");
        console.log("  --etherscan-api-key $BASESCAN_API_KEY \\");
        console.log("  ", address(basedCertificate), " \\");
        console.log("  src/BasedCertificate.sol:BasedCertificate");
        console.log("");

        console.log("forge verify-contract \\");
        console.log("  --chain-id 84532 \\");
        console.log("  --compiler-version v0.8.26 \\");
        console.log("  --etherscan-api-key $BASESCAN_API_KEY \\");
        console.log("  ", address(basedBadge), " \\");
        console.log("  src/BasedBadge.sol:BasedBadge");
    }
}