// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TicketNFT.sol";

contract DeployScript is Script {
    function run() external returns (TicketNFT) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy TicketNFT contract
        TicketNFT ticketNFT = new TicketNFT();

        console.log("TicketNFT deployed to:", address(ticketNFT));

        // Create a sample event for testing
        ticketNFT.createEvent(
            "Base Workshop Meet 3",
            "Learn about NFT Ticketing with OnchainKit",
            0.001 ether,  // 0.001 ETH per ticket
            100,          // max 100 tickets
            "ipfs://QmYourImageHash", // placeholder IPFS hash
            block.timestamp + 7 days,  // event in 1 week
            "Jakarta, Indonesia"
        );

        console.log("Sample event created with ID: 0");

        vm.stopBroadcast();

        return ticketNFT;
    }
}