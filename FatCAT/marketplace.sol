// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts@4.9.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.0/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC20/utils/SafeERC20.sol";
interface IConnected {
    struct MyNft {
        uint256 tokenId;
        uint256 mintTime;
        address mintContract;
        address mintArtist;
        uint artistFeePerAge;
        string uri;
    }
    /**
     * @dev update Token Id in the minted contract.
     */
    function updateTokenId(address _to,uint _tokenId,address seller) external;
    function update_TokenIdTime(uint _tokenId) external;
    function getTokenId(address _to) external view returns(MyNft[] memory);
    function getTokenUri(uint _tokenId) external view returns(string memory);

}
/**
 * @title MarketPlace
 */
contract Marketplace is ReentrancyGuard , Ownable{
    using SafeERC20 for IERC20;
    //Counter
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public nftAuctionCount;
    //Address
    address paymentToken;
    address tokenAddress;
    address public buyerFee;
    address public sellerFee;
    uint public buyerFeePerAge;
    uint public sellerFeePerAge;
    //Mapping
    mapping (address => mapping(uint256 => NFT)) public _idToNFT;
    mapping (uint => addressToken) public listCount;
    mapping (address => mapping (uint => nftAuction)) public NftAuction;
    mapping (uint => uint ) public userListCount;
    mapping (uint => addressToken) public auctionListCount;
    mapping (address => mapping(uint => mapping(uint=>userDetail))) public Bidding;
    mapping(uint => uint) public SelectedUser;
    mapping (address => mapping(uint => mapping(address=> mapping(uint=>uint)))) public BiddingCount;
    mapping (address => mapping(uint => mapping(address=>uint))) public userBiddingCount;
    //Struct
    struct NFT {
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        // uint256 start;
        // uint256 end;
        uint256 count;
        uint listTime;
        bool listed;
        address artist;
        uint artistFeePerAge;
    }
    struct nftAuction{
        address owner;
        uint tokenId;
        uint minimumBid;
        // uint start;
        // uint end;
        address artist;
        uint artistFeePerAge;
        uint listTime;
        bool isActive;
    }
    struct userDetail{
        address user;
        string userName;
        uint price;
        uint biddingTime;
        uint bidCount;
    }
    struct addressToken{
        address contractAddress;
        uint tokenId;
    }
    struct ListTokenId{
        nftAuction listedData;
        uint listCount;
        string uriData;
    }
    struct ListedNftTokenId{
        NFT listedData;
        uint listCount;
        string uriData;
    }
    struct MyNft {
        uint256 tokenId;
        uint256 mintTime;
        address mintContract;
        address mintArtist;
        uint artistFeePerAge;
        string uri;
    }
    //Event
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price, uint SoldTime);
    event Fee(address ArtistAddress,uint ArtistFee);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    event Claim(uint256 tokenId,address buyer,uint ClaimTime);
    //Constructor
    constructor(address _buyer,address _seller,uint _buyerFeePerAge, uint _sellerFeePerAge) {
        buyerFee = _buyer;
        sellerFee = _seller;
        sellerFeePerAge = _sellerFeePerAge;
        buyerFeePerAge = _buyerFeePerAge;
        // tokenAddress = _tokenAddress;
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in marketplace for specific time.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
        @param _mintContract set deployed nftContract Address
        @param _startTime & _endTime set the Listing Time
    */
    function ListNft(address _mintContract,uint256 _price,uint256 _tokenId,address artist,uint artistFeePerAge) public nonReentrant {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        // require(_startTime < _endTime,"Time Overflow!");
        _nftCount.increment();
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,address(this),_price,_nftCount.current(),block.timestamp,true,artist,artistFeePerAge);
        listCount[_nftCount.current()] = addressToken(_mintContract,_tokenId);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }   
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param listIndex is a counter of listed Nft's in Marketplace
        @param typ set the choice of payment method (1 for Ethereum & 2 for Erc20 Tokens)
        @param price set price of NFT 
    */
    function buyNft(uint listIndex,uint256 price) public payable nonReentrant {
        // uint startTime = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].start;
        // uint endTime = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].end; 
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        // require(startTime < block.timestamp && block.timestamp < endTime,"no longer available!");
        require(price >= _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price , "Not enough ether to cover asking price !!!");
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        IConnected(listCount[listIndex].contractAddress).updateTokenId(msg.sender,listCount[listIndex].tokenId,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller);
        uint buyerFeeCul =  (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * buyerFeePerAge) / 1000;
        uint sellerFeeCul = (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * sellerFeePerAge) / 1000;
       // uint royaltyAmount = (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * _royltyPercentage) / 100;
      
        uint artistFeePerAge = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].artistFeePerAge;
        uint artistFee = (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * artistFeePerAge) / 100;
        uint sellerAmount = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price - (artistFee + buyerFeeCul + sellerFeeCul);
        payable(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller).transfer(sellerAmount);
        //payable (_royalityAddress).transfer(royaltyAmount);
        payable (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].artist).transfer(artistFee);
        payable (buyerFee).transfer(buyerFeeCul);
        payable (sellerFee).transfer(sellerFeeCul);
        // if(typ == 1){ 
        //     payable(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller).transfer(sellerAmount);
        //     payable (_royalityAddress).transfer(royaltyAmount);
        // }  
        // else if(typ == 2){  
        //     IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller,sellerAmount);
        //     IERC20(tokenAddress).safeTransferFrom(msg.sender,_royalityAddress,royaltyAmount);
        // }
        // else{
        //     revert("Please Enter the correct payment Type");
        // }
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        IConnected(listCount[listIndex].contractAddress).update_TokenIdTime(listCount[listIndex].tokenId);
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit Fee(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].artist,artistFee);
        emit NFTSold(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, msg.value,block.timestamp);
    }
    // ============ CancelOffer FUNCTIONS ============
    /*
        @dev CancelOffer cancel offer that is listed
        @param listIndex is a counter of listed Nft's in Marketplace
    */
     
    function CancelOffer(uint listIndex) public nonReentrant {
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed,"Please List First !!!");
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller;
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price);
    }
    // ============ AuctionList FUNCTIONS ============
    /*
        @dev AuctionList list NFTs for Auction with tokenid & mint contract Address.
        @param _mintContract set deployed nftContract Address
        @param _tokenId that are minted by the nftContract
        @param _maxPrice set minimum price of NFT for Auction
        @param _startTime & _endTime set the Auction Listing & Ending Time respectively
        
    */
    function OfferList(address _mintContract,uint _tokenId,uint _maxPrice,address artist,uint artistFeePerAge) external {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
        // require(_startTime < _endTime,"Time Overflow!");
        nftAuctionCount.increment();
        NftAuction[_mintContract][_tokenId] = nftAuction(msg.sender,_tokenId,_maxPrice,artist,artistFeePerAge,block.timestamp,true);
        auctionListCount[nftAuctionCount.current()] = addressToken(_mintContract,_tokenId);
        userListCount[nftAuctionCount.current()] = 0; 
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId);
    }
    // ============ IncreaseAuctionTime FUNCTIONS ============
    /*
        @dev IncreaseAuctionTime Increase the Time For Auction.
        @param _mintContract set deployed nftContract Address
        @param _tokenId that are minted by the nftContract
        @param _totalBidTime set time of NFT for Auction
    */
    // function IncreaseAuctionTime(address _mintContract,uint256 _tokenId,uint256 _totalBidTime) external {
    //     require(_idToNFT[_mintContract][_tokenId].seller== msg.sender,"You are not Owner");
    //     require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
    //     require(NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
    //     require(_totalBidTime >= 1, "Bid Time Must Be One Hour!");
    //     NftAuction[_mintContract][_tokenId].start = block.timestamp;
    //     NftAuction[_mintContract][_tokenId].end = block.timestamp + (3600 * _totalBidTime);
    // }
    // ============ NftBidding FUNCTIONS ============
    /*
        @dev NftBidding set the bidding on _auctionListCount with name & bidding price.
        @param _auctionListCount is a counter of listed Nft's for Auction
        @param _name set bidder's name
        @param _price set bid price of NFT for Auction
    */
    function NftOffers(uint _auctionListCount,string memory _name, uint _price) external {
        address contractAddress = auctionListCount[_auctionListCount].contractAddress;
        uint tokenId = auctionListCount[_auctionListCount].tokenId;
        uint userCount = userBiddingCount[contractAddress][tokenId][msg.sender];
        require(NftAuction[contractAddress][tokenId].owner != msg.sender,"You are Not Eligible for Bidding");
        require(NftAuction[contractAddress][tokenId].isActive,"Not Listed In Offers!");
        // require(NftAuction[contractAddress][tokenId].start < block.timestamp ,"Bidding Not Start!");
        // require(_price >= NftAuction[contractAddress][tokenId].minimumBid,"Amount Should be greater than MinimumBid");
        // require(block.timestamp < NftAuction[contractAddress][tokenId].end,"Bidding is going on!");
        Bidding[contractAddress][tokenId][userListCount[_auctionListCount]+1] = userDetail(msg.sender,_name,_price,block.timestamp,userListCount[_auctionListCount]+1);
        BiddingCount[contractAddress][tokenId][msg.sender][userCount+1] = userListCount[_auctionListCount]+1;
        userBiddingCount[contractAddress][tokenId][msg.sender]++;
        userListCount[_auctionListCount]++;
    }
    // ============ cancelAuctionList FUNCTIONS ============
    /*
        @dev cancelAuctionList cancel the AuctionListed Nft.
        @param _auctionListCount is a counter of listed Nft's for Auction 
        
    */
    function cancelOfferList(uint _auctionListCount) external {
        require(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner == msg.sender,"Only Owner Can Cancel!!");
        ERC721(auctionListCount[_auctionListCount].contractAddress).transferFrom(address(this), msg.sender, auctionListCount[_auctionListCount].tokenId);
        NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive = false;
        auctionListCount[_auctionListCount] = auctionListCount[nftAuctionCount.current()];
        userListCount[_auctionListCount] = userListCount[nftAuctionCount.current()];
        delete auctionListCount[nftAuctionCount.current()];
        delete userListCount[nftAuctionCount.current()];
        nftAuctionCount.decrement();
    }
    // ============ ClaimNFT FUNCTIONS ============
    /*
        @dev ClaimNFT highest bidder claim his/her Nft.
        @param _auctionListCount is a counter of listed Nft's for Auction
        @param typ set the choice of payment method (1 for Ethereum & 2 for Erc20 Tokens)
    */
    function ClaimNFT(uint _auctionListCount) external payable {
        require(SelectedUser[_auctionListCount] != 0 ,"Please wait...");
        // require(block.timestamp > NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].end,"Bidding is still going on!");
        userDetail memory selectedUser;
        selectedUser = Bidding[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId][SelectedUser[_auctionListCount]];
        require(selectedUser.user == msg.sender ,"you are not sellected bidder");
        require(msg.value >= selectedUser.price,"Incorrect Price");
        // uint256 artistAmountPerAge = NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].artistFeePerAge;
        // address artist = NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].artist;
         uint buyerFeeCul =  (_idToNFT[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].price * buyerFeePerAge) / 1000;
        uint sellerFeeCul = (_idToNFT[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].price * sellerFeePerAge) / 1000;
        //uint256 royaltyAmount = (selectedUser.price * _royltyPercentage) / 100;
        uint256 artistAmount = (selectedUser.price *  NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].artistFeePerAge) / 100;
        uint256 sellerAmount = selectedUser.price - (artistAmount + buyerFeeCul + sellerFeeCul);
        payable(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner).transfer(sellerAmount);
        //payable(_royalityAddress).transfer(royaltyAmount);
        payable(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].artist).transfer(artistAmount);
        payable (buyerFee).transfer(buyerFeeCul);
        payable (sellerFee).transfer(sellerFeeCul);
        // if(typ == 1){ 
        //     require(msg.value >= selectedUser.price,"Incorrect Price");
        //     payable(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner).transfer(sellerAmount);
        //     payable(_royalityAddress).transfer(royaltyAmount);
        //     payable(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].artist).transfer(artistAmount);
        // }  
        // else if(typ == 2){  
        //     IERC20(tokenAddress).safeTransferFrom(selectedUser.user,NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner,sellerAmount);
        //     IERC20(tokenAddress).safeTransferFrom(selectedUser.user,_royalityAddress,royaltyAmount);
        // }
        // else{
        //     revert("Please Enter the correct payment Type");
        // }
        ERC721(auctionListCount[_auctionListCount].contractAddress).transferFrom(address(this), msg.sender, auctionListCount[_auctionListCount].tokenId);
        emit Claim(auctionListCount[_auctionListCount].tokenId,msg.sender,block.timestamp);
        IConnected(auctionListCount[_auctionListCount].contractAddress).updateTokenId(msg.sender,auctionListCount[_auctionListCount].tokenId,NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner);
        NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive = false;
        IConnected(auctionListCount[_auctionListCount].contractAddress).update_TokenIdTime(auctionListCount[_auctionListCount].tokenId);
        auctionListCount[_auctionListCount] = auctionListCount[nftAuctionCount.current()];       
        userListCount[_auctionListCount] = userListCount[nftAuctionCount.current()];
        delete SelectedUser[_auctionListCount];
        delete auctionListCount[nftAuctionCount.current()];
        delete userListCount[nftAuctionCount.current()];
        nftAuctionCount.decrement();
       
    }
    // ============ selectUser FUNCTIONS ============
    /*
        @dev cancelBid cancel the bid of user 
        @param _auctionListIndex is a counter of listed Nft's for Auction
    */
    function cancelOfferPrice(uint _auctionListIndex) external {
        address contractAddress = auctionListCount[_auctionListIndex].contractAddress;
        uint tokenId = auctionListCount[_auctionListIndex].tokenId;
        uint userCount = userBiddingCount[contractAddress][tokenId][msg.sender];
        uint count = BiddingCount[contractAddress][tokenId][msg.sender][userCount];
        require( Bidding[contractAddress][tokenId][count].user == msg.sender,"please bid first!");
        // require(block.timestamp < NftAuction[contractAddress][tokenId].end,"Auction Ended!");
        delete Bidding[contractAddress][tokenId][count];
        delete BiddingCount[contractAddress][tokenId][msg.sender][count];
        userBiddingCount[contractAddress][tokenId][msg.sender]--;
    }
    // ============ selectUser FUNCTIONS ============
    /*
        @dev selectUser getting highest bidder overall.
        @param _auctionListCount 
        @return userDetail array of user's data who has done bidding
    */
    function selectUser(uint _auctionListCount,uint bidCount) public {
        SelectedUser[_auctionListCount] = bidCount;
        // userDetail memory selectedUser;
        // selectedUser = Bidding[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId][bidCount];
        // return (selectedUser);
    }
    // ============ getBiddingHistory FUNCTIONS ============
    /*
        @dev getBiddingHistory showing all bidding history on Listcount.
        @param _listCount is a counter of listed Nft's in Marketplace
        @return userDetail array of user's data who has done bidding
    */
    function getBiddingHistory(uint _listCount) external view returns(userDetail[] memory){
        address contractAddress = auctionListCount[_listCount].contractAddress;
        uint tokenId = auctionListCount[_listCount].tokenId;
        uint indexCount = 0;
        userDetail[] memory BiddingHistory = new userDetail[](userListCount[_listCount]);
        for(uint i=1; i <= userListCount[_listCount];i++){
            BiddingHistory[indexCount] = Bidding[contractAddress][tokenId][i];
            indexCount++;
        }
        return BiddingHistory;
    }
    // function getNFTDetail(address _to, address contractAddress) external view returns (IConnected.MyNft[] memory) {
    //     IConnected.MyNft[] memory myNFT = IConnected(contractAddress).getTokenId(_to);
    //     return myNFT;
    // }
    function getNFTDetail(address _to, address[] memory contractAddresses) external view returns (MyNft[][] memory) {
        MyNft[][] memory myNFT = new MyNft[][](contractAddresses.length);
        for (uint i = 0; i < contractAddresses.length; i++) {
            IConnected.MyNft[] memory connectedNft = IConnected(contractAddresses[i]).getTokenId(_to);
            myNFT[i] = new MyNft[](connectedNft.length);
            for(uint j = 0 ; j < connectedNft.length ; j++){
                myNFT[i][j] = MyNft(connectedNft[j].tokenId,connectedNft[j].mintTime,connectedNft[j].mintContract,connectedNft[j].mintArtist,connectedNft[j].artistFeePerAge,connectedNft[j].uri);
            }
        }
        return (myNFT);
    }
    function getAllListedNfts() public view returns (ListedNftTokenId[] memory,ListTokenId[] memory) {
        uint listNft = (_nftCount.current());
        ListedNftTokenId[] memory listedNFT = new ListedNftTokenId[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if (_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed) {
                listedNFT[listedIndex] = ListedNftTokenId(_idToNFT[listCount[i].contractAddress][listCount[i].tokenId],i,IConnected(listCount[i].contractAddress).getTokenUri(listCount[i].tokenId));
                listedIndex++;
            }
        }
        listNft = (nftAuctionCount.current());
        ListTokenId[] memory auctionListNFT = new ListTokenId[](listNft);
        uint listedIndexCount = 0;
        for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
            if (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive) {
                auctionListNFT[listedIndexCount] = ListTokenId(NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId],i,IConnected(auctionListCount[i].contractAddress).getTokenUri(auctionListCount[i].tokenId));
                listedIndexCount++;
            }
        }
        return (listedNFT,auctionListNFT);
        // return (listedNFT);
    }
    function setBuyerFeeAddress(address _address) public onlyOwner{
        buyerFee = _address;
    }
    function setSellerFeeAddress(address _address) public onlyOwner{
        sellerFee = _address;
    }
    function setBuyerFee(uint _setBuyerFee) public onlyOwner{
        buyerFeePerAge = _setBuyerFee;
    }
    function setSellerFee(uint _setSellerFee) public onlyOwner{
        sellerFeePerAge = _setSellerFee;
    }

    //0xd650411C116AC40F3a4f7042055C3ad5C747b55C minting
    //0x49f0A3c16562452f18613430d64B0e69922C9B34 marketplace
}