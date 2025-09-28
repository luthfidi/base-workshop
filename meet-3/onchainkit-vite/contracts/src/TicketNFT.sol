// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TicketNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    uint256 private _eventIdCounter;

    struct Event {
        string name;
        string description;
        uint256 price;
        uint256 maxSupply;
        uint256 sold;
        bool active;
        string imageURI;
        uint256 eventDate;
        string venue;
    }

    mapping(uint256 => Event) public events;
    mapping(uint256 => uint256) public ticketToEvent; // tokenId => eventId
    mapping(uint256 => bool) public ticketUsed; // tokenId => used for check-in

    event EventCreated(uint256 indexed eventId, string name, uint256 price, uint256 maxSupply);
    event TicketMinted(uint256 indexed tokenId, uint256 indexed eventId, address indexed buyer);
    event TicketCheckedIn(uint256 indexed tokenId, uint256 indexed eventId);

    constructor() ERC721("TicketNFT", "TNFT") Ownable(msg.sender) {}

    function createEvent(
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _maxSupply,
        string memory _imageURI,
        uint256 _eventDate,
        string memory _venue
    ) external onlyOwner returns (uint256) {
        uint256 eventId = _eventIdCounter;
        _eventIdCounter++;

        events[eventId] = Event({
            name: _name,
            description: _description,
            price: _price,
            maxSupply: _maxSupply,
            sold: 0,
            active: true,
            imageURI: _imageURI,
            eventDate: _eventDate,
            venue: _venue
        });

        emit EventCreated(eventId, _name, _price, _maxSupply);
        return eventId;
    }

    function mintTicket(uint256 _eventId) external payable returns (uint256) {
        Event storage eventData = events[_eventId];

        require(eventData.active, "Event not active");
        require(eventData.sold < eventData.maxSupply, "Sold out");
        require(msg.value >= eventData.price, "Insufficient payment");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(msg.sender, tokenId);

        ticketToEvent[tokenId] = _eventId;
        eventData.sold++;

        // Generate metadata URI
        string memory metadataURI = generateTokenURI(_eventId, tokenId);
        _setTokenURI(tokenId, metadataURI);

        emit TicketMinted(tokenId, _eventId, msg.sender);

        return tokenId;
    }

    function checkInTicket(uint256 _tokenId) external onlyOwner {
        require(_ownerOf(_tokenId) != address(0), "Token does not exist");
        require(!ticketUsed[_tokenId], "Ticket already used");

        ticketUsed[_tokenId] = true;
        uint256 eventId = ticketToEvent[_tokenId];

        emit TicketCheckedIn(_tokenId, eventId);
    }

    function verifyTicket(uint256 _tokenId) external view returns (
        bool exists,
        address owner,
        uint256 eventId,
        bool used,
        string memory eventName
    ) {
        if (_ownerOf(_tokenId) == address(0)) {
            return (false, address(0), 0, false, "");
        }

        address ticketOwner = ownerOf(_tokenId);
        uint256 eventIdForTicket = ticketToEvent[_tokenId];
        bool isUsed = ticketUsed[_tokenId];
        string memory name = events[eventIdForTicket].name;

        return (true, ticketOwner, eventIdForTicket, isUsed, name);
    }

    function generateTokenURI(uint256 _eventId, uint256 _tokenId) internal view returns (string memory) {
        Event memory eventData = events[_eventId];

        // Simple JSON metadata - in production, this would be stored on IPFS
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"', eventData.name, ' Ticket #', Strings.toString(_tokenId), '",',
                '"description":"', eventData.description, '",',
                '"image":"', eventData.imageURI, '",',
                '"attributes":[',
                    '{"trait_type":"Event ID","value":"', Strings.toString(_eventId), '"},',
                    '{"trait_type":"Ticket ID","value":"', Strings.toString(_tokenId), '"},',
                    '{"trait_type":"Venue","value":"', eventData.venue, '"},',
                    '{"trait_type":"Event Date","value":"', Strings.toString(eventData.eventDate), '"}',
                ']}'
            )))
        ));
    }

    function getEvent(uint256 _eventId) external view returns (Event memory) {
        return events[_eventId];
    }

    function getEventCount() external view returns (uint256) {
        return _eventIdCounter;
    }

    function getTicketCount() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function toggleEventStatus(uint256 _eventId) external onlyOwner {
        events[_eventId].active = !events[_eventId].active;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Override required functions for ERC721URIStorage
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// Base64 encoding library for metadata
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               let input := mload(dataPtr)

               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}