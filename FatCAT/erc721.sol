// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts@4.9.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.9.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.0/utils/Counters.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract Minting is ERC721URIStorage, Ownable {
    // using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;
    struct TokenIdByCollection {
        uint256[] tokenIds;
    }
    struct NFT {
        uint256 mintTime;
        address mintArtist;
        uint artistFeePerAge;
        }
    struct MyNft {
        uint256 tokenId;
        uint256 mintTime;
        address mintContract;
        address mintArtist;
        uint artistFeePerAge;
        string uri;
    }
    mapping(address => mapping(uint256 => uint256)) public TokenId;
    mapping(address => uint256) public count;
    mapping(string => TokenIdByCollection) private tokenIdByCollection;
    mapping (uint => NFT) public NFTMetadata;
    address public adminAddress;
    // mapping(string => uint256) public alreadyMintedQuantity;
    // address public mintPriceReceiver;
    // address public transferFeeReceiver;
    // address tokenAddress;
    // address public royaltyAddress;
    // mapping (address => uint) public ArtistAmount;
    event SafeMinting(uint256 tokenId,address Minter,uint MintingTime);
    constructor(address _adminAddress)
        ERC721("3DotLink", "3.LINK")
    {
        adminAddress = _adminAddress;
    }
    function safeMint(string memory uri,address artist,uint artistFeePerAge,string memory collectionId) public payable {
        // require((StartTime < block.timestamp) && (block.timestamp < EndTime),"Time Overflow");
        // uint256 usedQuantity = alreadyMintedQuantity[NFT_doc];
        // require((usedQuantity + mintQuantity) <= TotalQuantity,"Remaining NFTQuantity is Less than Your NFTQuantity");
        // uint256 calculatedFeePrice = calculateReceiverPrice(feePercentage,(perNFTPrice*mintQuantity));
        _tokenIdCounter.increment();
        TokenId[msg.sender][count[msg.sender] + 1] = _tokenIdCounter.current();
        _safeMint(msg.sender, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), uri);
        count[msg.sender]++;
        NFTMetadata[_tokenIdCounter.current()] = NFT(block.timestamp,artist,artistFeePerAge);
        tokenIdByCollection[collectionId].tokenIds.push(_tokenIdCounter.current());
        // alreadyMintedQuantity[NFT_doc] += mintQuantity;
        // ArtistAmount[artist] += ((perNFTPrice*mintQuantity) - calculatedFeePrice);
        emit SafeMinting(_tokenIdCounter.current(),msg.sender,block.timestamp);
    }
    // function calculateReceiverPrice(uint256 _feePercentage, uint256 _TotalPrice)
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     return ((_TotalPrice * _feePercentage) / 1000);
    // }
    // function viewArtistAmount(address to) public view returns(uint256 artist) {
    //     return ArtistAmount[to];
    //     // payable(to).transfer(ArtistAmount[to]);
    //     // delete ArtistAmount[to];
    // }
    function getTokenId(address to) public view returns (MyNft[] memory) {
        MyNft[] memory myArray = new MyNft[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            myArray[i] = MyNft(TokenId[to][i + 1],NFTMetadata[TokenId[to][i + 1]].mintTime,address(this),NFTMetadata[TokenId[to][i + 1]].mintArtist,NFTMetadata[TokenId[to][i + 1]].artistFeePerAge,tokenURI(TokenId[to][i + 1]));
        }
        return myArray;
    }
    function updateTokenId(address _to,uint _tokenId,address _seller) external {
        TokenId[_to][count[_to] + 1] = _tokenId;
        MyNft[] memory myArray =  getTokenId(_seller);
        for(uint i=0 ; i < myArray.length ; i++){
            if(myArray[i].tokenId == _tokenId){
                TokenId[_seller][i+1] = TokenId[_seller][count[_seller]];
                count[_seller]--;
            }
        }
        count[_to]++;
    }
    function update_TokenIdTime(uint _tokenId) external {
        NFTMetadata[_tokenId].mintTime = block.timestamp;
    }
    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override
    {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function getTokenIdsByCollection(string memory collectionId)
        public
        view
        returns (MyNft[] memory)
    {
        uint256[] memory tokenIds = tokenIdByCollection[collectionId].tokenIds;
        MyNft[] memory myArray = new MyNft[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 currentTokenId = tokenIds[i];
            myArray[i] = MyNft(currentTokenId,NFTMetadata[currentTokenId].mintTime,address(this),NFTMetadata[currentTokenId].mintArtist,NFTMetadata[currentTokenId].artistFeePerAge,tokenURI(currentTokenId));
        }
        return myArray;
    }
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    // function setMintPriceReceiver(address _mintPriceReceiver) public   {
    //     mintPriceReceiver=_mintPriceReceiver;
    // }
    // function setTransferFeeReceiver(address _transferFeeReceiver) public {
    //     transferFeeReceiver=_transferFeeReceiver;
    // }
    // function setRoyaltyAddress(address _royaltyAddress) public {
    //     royaltyAddress = _royaltyAddress; 
    // }
    function setAdminAddress(address _adminAddress) external {
        require(adminAddress==msg.sender,"You are not Admin");
        adminAddress = _adminAddress;
    }
    function getTokenUri(uint tokenId) external view returns(string memory){
        return tokenURI(tokenId);
    }
}