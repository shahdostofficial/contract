// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@5.0.1/access/Ownable.sol";

contract LegalAiContract is ERC721, ERC721URIStorage, Ownable {
    mapping(address => bool) public whiteList;
    uint public _nextTokenId;
    address[] public whilistedAddress;
    uint256 public whitelistedArtistFee;
    uint256 public nonWhitelistedArtistFee;
    constructor(address initialOwner, uint256 _whitelistedArtistFee, uint256 _nonWhitelistedArtistFee ) ERC721("LegalAl", "AI") Ownable(initialOwner)
    {
        whitelistedArtistFee = _whitelistedArtistFee;
        nonWhitelistedArtistFee = _nonWhitelistedArtistFee;

    }
    function WhiteList(address _address)payable  public {
        require(_address != address(0),"WhiteListed Address should not be null address!");
        require(!whiteList[_address],"This Address is already WhiteListed!");
        require(msg.value == 1 ether, "Insufficient fee!");
        payable(owner()).transfer(msg.value);
        whilistedAddress.push(_address);
        whiteList[_address] = true;
    }
    function safeMint(address to, string memory uri) payable public {
        if (whiteList[to]) {
            require(msg.value == whitelistedArtistFee, "Fee exactly equal to the whitelistedArtistFee!");
            payable(owner()).transfer(whitelistedArtistFee);
        } else {
            require(msg.value == nonWhitelistedArtistFee, "Fee exactly equal to the nonWhitelistedArtistFee!");
            payable(owner()).transfer(nonWhitelistedArtistFee);
        }
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function artistList() public view returns (address[] memory) {
        return whilistedAddress;
    }
}
