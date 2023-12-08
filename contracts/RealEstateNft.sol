// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// for implementing ERC721 standards
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Ownable will be used to restrict some functionalities and used only by contract owner
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateNft is ERC721URIStorage, Ownable {
    // a counter for real estate tokens
    uint256 private realEstateCounter;

    // constructor
    constructor() Ownable(msg.sender) ERC721("RealEstateNft", "REN") {
        // so first real estate token minted it will have an id = 1
        realEstateCounter = 1;
    }

    // Real Estate Object structure
    struct RENft {
        // string name; -- we can save the owner's name
        string location; // to store the address/location of the real estate
        uint256 squareFeetArea; // square feet area of that real estate
        uint256 price; // current market price of that real estate
        bool forSale; // is it for sale or not
    }

    // mapping of id's to real estate
    mapping(uint256 => RENft) private realEstates;

    // Event will be triggered when real estate is being tokenized as an nft
    event RealEstateNFTCreated(
        uint256 realEstateNftID,
        string location,
        uint256 squareFeetArea,
        uint256 price,
        bool forSale,
        string realEstateTokenURI
    );

    // Event will be triggered if a real estate is being listed for sale
    event RealEstateForSale(uint256 realEstateNftID, uint256 price);

    // Event will be triggered if a real estate is being sold to someone
    event RealEstateSold(uint256 realEstateNftID, address buyer, uint256 price);

    // Function to tokenize real estate and mint a NFT
    function mintRealEstate(
        string memory _location,
        uint256 _squareFeetArea,
        uint256 _price,
        string memory realEstateTokenURI
    ) external onlyOwner {
        require(_squareFeetArea > 0, "Area must be greater than 0 square foot");
        require(_price > 0, "Price of real estate must be greater than 0");

        RENft memory newRealEstateNft = RENft({
            location: _location,
            squareFeetArea: _squareFeetArea,
            price: _price,
            forSale: false
        });

        // minting the nft and assign it to current owner only along with it's metadata
        _mint(msg.sender, realEstateCounter);
        _setTokenURI(realEstateCounter, realEstateTokenURI);

        realEstates[realEstateCounter] = newRealEstateNft;

        // trigger the event
        emit RealEstateNFTCreated(
            realEstateCounter,
            _location,
            _squareFeetArea,
            _price,
            false,
            realEstateTokenURI
        );

        // incrementing the counter;
        realEstateCounter++;
    }

    // Function to make a real estate available for sale or auction
    function updateRealEstateForSale(
        uint256 _realEstateId,
        uint256 price
    ) external onlyOwner {
        // some pre-checks
        require(
            ownerOf(_realEstateId) == msg.sender,
            "You are not the owner of real estate"
        );
        require(price > 0, "Price must be greater than 0");

        // update the real estate object
        realEstates[_realEstateId].forSale = true;
        realEstates[_realEstateId].price = price;

        // trigger the event
        emit RealEstateForSale(_realEstateId, price);
    }

    function buyRealEstate(uint256 _realEstateId) external payable {
        // some pre-checks
        require(
            realEstates[_realEstateId].forSale,
            "Real Estate is not FOR SALE!!"
        );
        require(
            msg.value == realEstates[_realEstateId].price,
            "Kindly enter the appropriate amount"
        );

        address seller = ownerOf(_realEstateId);

        // transfering the ownership of real estate to the buyer
        _transfer(seller, msg.sender, _realEstateId);

        // real estate is no longer required for sale
        realEstates[_realEstateId].forSale = false;

        emit RealEstateSold(_realEstateId, msg.sender, msg.value);

        // pay the price to seller
        payable(seller).transfer(msg.value);
    }

    // function to get all real estates
    function getAllRealEstates() external view returns (RENft[] memory) {
        RENft[] memory allRealEstates = new RENft[](realEstateCounter - 1);

        for (uint256 i = 1; i < realEstateCounter; i++) {
            allRealEstates[i - 1] = realEstates[i];
        }

        return allRealEstates;
    }

    // function which get real estate information
    function getRealEstateById(
        uint256 _realEstateId
    ) external view returns (RENft memory) {
        return realEstates[_realEstateId];
    }
}
